import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';

/// Renders an image served by our own API's protected /Files/view endpoint,
/// fetching it through the authenticated ApiClient instead of a bare
/// Image.network (which cannot attach an Authorization header).
class AuthenticatedNetworkImage extends StatelessWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) {
      return _fallback(context);
    }

    final api = AppScope.of(context).api;

    return FutureBuilder<Uint8List>(
      future: api.getBytes('/Files/view?url=${Uri.encodeQueryComponent(raw)}'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingWidget ??
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
