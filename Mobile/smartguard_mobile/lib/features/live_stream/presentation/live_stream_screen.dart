import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/live_stream_controller.dart';
import '../application/live_stream_state.dart';

class LiveStreamScreen extends ConsumerWidget {
  const LiveStreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveStreamControllerProvider);
    final controller = ref.read(liveStreamControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Stream (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: state.status == LiveStreamStatus.connecting
                      ? null
                      : controller.connect,
                  child: const Text('Connect'),
                ),
                OutlinedButton(
                  onPressed: controller.disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final LiveStreamState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      LiveStreamStatus.idle => 'Idle',
      LiveStreamStatus.connecting => 'Connecting',
      LiveStreamStatus.connected => 'Connected',
      LiveStreamStatus.error => 'Error',
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
