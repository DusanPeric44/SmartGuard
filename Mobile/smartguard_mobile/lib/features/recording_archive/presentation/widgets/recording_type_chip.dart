import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';

class RecordingTypeChip extends StatelessWidget {
  const RecordingTypeChip({super.key, required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) {
    final label = typeName.trim().isEmpty ? 'Unknown' : typeName.trim();
    final normalized = label.toLowerCase();

    final (fg, bg) = normalized.contains('face')
        ? (Colors.green.shade700, Colors.green.shade50)
        : (Colors.amber.shade900, Colors.amber.shade50);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
