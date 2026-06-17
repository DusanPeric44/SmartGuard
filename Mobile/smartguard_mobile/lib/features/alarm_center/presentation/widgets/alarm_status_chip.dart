import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../domain/alarm.dart';

class AlarmStatusChip extends StatelessWidget {
  const AlarmStatusChip({
    super.key,
    required this.status,
    required this.statusName,
  });

  final AlarmUiStatus status;
  final String? statusName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = switch (status) {
      AlarmUiStatus.pending => 'Pending',
      AlarmUiStatus.confirmed => 'Confirmed',
      AlarmUiStatus.resolved => 'Resolved',
      AlarmUiStatus.unknown =>
        (statusName?.trim().isNotEmpty ?? false)
            ? statusName!.trim()
            : 'Unknown',
    };

    final (border, fg, bg) = switch (status) {
      AlarmUiStatus.pending => (
        Colors.amber.shade700,
        Colors.amber.shade900,
        Colors.amber.shade50,
      ),
      AlarmUiStatus.confirmed => (
        scheme.error,
        scheme.error,
        Colors.transparent,
      ),
      AlarmUiStatus.resolved => (
        Colors.green.shade700,
        Colors.green.shade700,
        Colors.green.shade50,
      ),
      AlarmUiStatus.unknown => (
        scheme.outline,
        scheme.onSurfaceVariant,
        Colors.transparent,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
