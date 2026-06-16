import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';

class AlarmErrorBanner extends StatelessWidget {
  const AlarmErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.spaceM),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppDimens.cardRadius,
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
