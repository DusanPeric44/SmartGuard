import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';

class KnownPersonsInfoCard extends StatelessWidget {
  const KnownPersonsInfoCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDimens.cardRadius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
