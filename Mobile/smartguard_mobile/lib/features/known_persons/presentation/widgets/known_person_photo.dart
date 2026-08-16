import 'package:flutter/material.dart';

import '../../../../core/widgets/authenticated_network_image.dart';

class KnownPersonPhoto extends StatelessWidget {
  const KnownPersonPhoto({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    if (url == null || url!.trim().isEmpty) {
      return fallback;
    }

    return AuthenticatedNetworkImage(
      url: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: fallback,
    );
  }
}
