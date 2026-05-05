import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recording_archive_controller.dart';
import '../application/recording_archive_state.dart';

class RecordingArchiveScreen extends ConsumerWidget {
  const RecordingArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingArchiveControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Archive (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == RecordingArchiveStatus.loading
                  ? null
                  : () => ref
                        .read(recordingArchiveControllerProvider.notifier)
                        .refresh(),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: state.recordingIds.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final id = state.recordingIds[index];
                  return ListTile(title: Text('Recording $id'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final RecordingArchiveState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      RecordingArchiveStatus.idle => 'Idle',
      RecordingArchiveStatus.loading => 'Loading',
      RecordingArchiveStatus.ready => 'Ready',
      RecordingArchiveStatus.error => 'Error',
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
