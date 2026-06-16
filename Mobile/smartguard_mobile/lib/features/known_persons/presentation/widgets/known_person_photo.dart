import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

class KnownPersonPhoto extends StatelessWidget {
  const KnownPersonPhoto({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = _resolveImageUrl(url);
    if (u == null || u.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.person,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      u,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  String? _resolveImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.resolve(value).toString();
  }
}
