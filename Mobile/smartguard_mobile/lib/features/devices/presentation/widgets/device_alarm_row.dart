import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../alarm_center/domain/alarm.dart';

class DeviceAlarmRow extends StatelessWidget {
  const DeviceAlarmRow({super.key, required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (alarm.uiStatus) {
      AlarmUiStatus.pending => Icons.warning_amber_rounded,
      AlarmUiStatus.confirmed => Icons.report_rounded,
      AlarmUiStatus.resolved => Icons.check_circle_rounded,
      AlarmUiStatus.unknown => Icons.notifications_outlined,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: ListTile(
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(alarm.title.trim().isEmpty ? 'Alarm' : alarm.title),
        subtitle: alarm.message.trim().isEmpty ? null : Text(alarm.message),
      ),
    );
  }
}
