import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/alarm_center_controller.dart';
import '../application/alarm_center_state.dart';

class AlarmCenterScreen extends ConsumerWidget {
  const AlarmCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alarmCenterControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alarm Center (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 12),
            Text('Active alarms: ${state.activeCount}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == AlarmCenterStatus.loading
                  ? null
                  : () => ref
                        .read(alarmCenterControllerProvider.notifier)
                        .refresh(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final AlarmCenterState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      AlarmCenterStatus.idle => 'Idle',
      AlarmCenterStatus.loading => 'Loading',
      AlarmCenterStatus.ready => 'Ready',
      AlarmCenterStatus.error => 'Error',
    };

    return Row(
      children: [
        Text('Status: $label'),
        if (state.message != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
