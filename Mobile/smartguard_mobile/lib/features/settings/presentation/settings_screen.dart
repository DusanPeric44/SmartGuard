import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';
import '../application/settings_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == SettingsStatus.loading
                  ? null
                  : () => ref.read(settingsControllerProvider.notifier).load(),
              child: const Text('Load'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push notifications'),
              value: state.pushEnabled,
              onChanged: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .togglePush(value),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      SettingsStatus.idle => 'Idle',
      SettingsStatus.loading => 'Loading',
      SettingsStatus.ready => 'Ready',
      SettingsStatus.error => 'Error',
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
