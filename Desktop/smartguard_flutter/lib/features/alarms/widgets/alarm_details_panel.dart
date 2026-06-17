import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarms_format.dart';

class AlarmDetailsPanel extends StatelessWidget {
  const AlarmDetailsPanel({
    super.key,
    required this.alert,
    required this.statusName,
    required this.typeName,
    required this.isBusy,
    required this.onConfirm,
    required this.onResolve,
    required this.onDismiss,
  });

  final AlertRow? alert;
  final String? statusName;
  final String? typeName;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = alert;
    if (a == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Select an alert to see details.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final status = (statusName ?? '').trim();
    final lower = status.toLowerCase();
    final canConfirm = lower.contains('pending');
    final canResolve = lower.contains('confirmed');
    final canDismiss = lower.contains('pending');

    final deviceLabel = a.device?.name?.isEmpty ?? true
        ? deviceFallback(a.deviceId)
        : a.device?.name ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alarm', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _kv('Alarm ID', 'ALM-${a.id}'),
            _kv(
              'Type',
              (typeName ?? '-').trim().isEmpty ? '-' : typeName ?? '',
            ),
            _kv('Status', status.isEmpty ? '-' : status),
            _kv('Device', deviceLabel),
            _kv(
              'Time',
              a.linkedEvent?.timestamp == null
                  ? '-'
                  : fmtDateTime(a.linkedEvent?.timestamp ?? DateTime.now()),
            ),
            if (canResolve || canConfirm || canDismiss)
              Row(
                children: [
                  if (canResolve)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onResolve,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Resolved'),
                      ),
                    ),
                  if (canConfirm) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onConfirm,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.report_gmailerrorred_outlined),
                        label: const Text('Confirm Threat'),
                      ),
                    ),
                  ],
                  if (canDismiss) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed: isBusy ? null : onDismiss,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.close),
                        label: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k)),
          const SizedBox(width: 10),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
