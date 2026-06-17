import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/alarm.dart';
import 'alarm_audit_details.dart';
import 'alarm_format.dart';
import 'alarm_status_chip.dart';

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    super.key,
    required this.alarm,
    required this.canAct,
    required this.busy,
    required this.onConfirm,
    required this.onDismiss,
  });

  final Alarm alarm;
  final bool canAct;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = alarm.uiStatus;
    final showActions = canAct && status == AlarmUiStatus.pending;

    final icon = switch (status) {
      AlarmUiStatus.pending => Icons.warning_amber_rounded,
      AlarmUiStatus.confirmed => Icons.report_rounded,
      AlarmUiStatus.resolved => Icons.check_circle_rounded,
      AlarmUiStatus.unknown => Icons.notifications_outlined,
    };

    final iconColor = switch (status) {
      AlarmUiStatus.pending => Colors.amber.shade700,
      AlarmUiStatus.confirmed => scheme.error,
      AlarmUiStatus.resolved => Colors.green.shade700,
      AlarmUiStatus.unknown => scheme.onSurfaceVariant,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppDimens.spaceM),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimens.spaceM,
          0,
          AppDimens.spaceM,
          AppDimens.spaceM,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          alarm.title.trim().isEmpty ? 'Alarm' : alarm.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppDimens.spaceXs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alarm.message.trim().isNotEmpty)
                Text(
                  alarm.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppDimens.spaceS),
              Text(
                formatAlarmDate(alarm.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        trailing: AlarmStatusChip(status: status, statusName: alarm.statusName),
        children: [
          if (_resolveImageUrl(alarm.linkedEventImagePath) case final u?)
            ClipRRect(
              borderRadius: AppDimens.cardRadius,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  u,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: AppDimens.spaceM),
          AlarmAuditDetails(alarm: alarm),
          if (showActions) ...[
            const SizedBox(height: AppDimens.spaceM),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: busy ? AppStrings.disabledActionInProgress : '',
                    child: FilledButton(
                      onPressed: busy ? null : onConfirm,
                      child: const Text(AppStrings.alarmActionConfirm),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceM),
                Expanded(
                  child: Tooltip(
                    message: busy ? AppStrings.disabledActionInProgress : '',
                    child: OutlinedButton(
                      onPressed: busy ? null : onDismiss,
                      child: const Text(AppStrings.alarmActionDismiss),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String? _resolveImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.resolve(value).toString();
  }
}
