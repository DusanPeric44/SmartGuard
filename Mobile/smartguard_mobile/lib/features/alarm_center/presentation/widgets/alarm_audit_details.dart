import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/alarm.dart';
import 'alarm_format.dart';

class AlarmAuditDetails extends StatelessWidget {
  const AlarmAuditDetails({super.key, required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = switch (alarm.uiStatus) {
      AlarmUiStatus.pending => 'Pending',
      AlarmUiStatus.confirmed => 'Confirmed',
      AlarmUiStatus.resolved => 'Resolved',
      AlarmUiStatus.unknown =>
        (alarm.statusName?.trim().isNotEmpty ?? false)
            ? alarm.statusName!.trim()
            : 'Unknown',
    };

    final rows = <(String, String)>[
      (AppStrings.alarmDetailStatusLabel, statusLabel),
      if (alarm.createdAt != null)
        (AppStrings.alarmDetailCreatedLabel, formatAlarmDate(alarm.createdAt)),
      if ((alarm.dismissalReason?.trim().isNotEmpty ?? false))
        (AppStrings.alarmDetailReasonLabel, alarm.dismissalReason!.trim()),
      if ((alarm.handledBy?.trim().isNotEmpty ?? false))
        (
          AppStrings.alarmDetailHandledByLabel,
          alarm.handledAt != null
              ? '${alarm.handledBy!.trim()} · ${formatAlarmDate(alarm.handledAt)}'
              : alarm.handledBy!.trim(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
