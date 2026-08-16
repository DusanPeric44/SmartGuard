import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

/// Renders an image served by our own API's protected /Files/view endpoint,
/// fetching it through the authenticated Dio client instead of a bare
/// Image.network (which cannot attach an Authorization header).
class AuthenticatedNetworkImage extends ConsumerWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) {
      return _fallback(context);
    }

    final dio = ref.watch(dioProvider);

    return FutureBuilder<Uint8List>(
      future: _fetch(dio, raw),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder ??
              const Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _fallback(context);
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _fallback(context),
        );
      },
    );
  }

  Future<Uint8List> _fetch(Dio dio, String rawUrl) async {
    final response = await dio.get<List<int>>(
      '/Files/view',
      queryParameters: {'url': rawUrl},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Widget _fallback(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
