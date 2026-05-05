import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notifications_controller.dart';
import '../application/notifications_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == NotificationsStatus.loading
                  ? null
                  : () => ref
                        .read(notificationsControllerProvider.notifier)
                        .refresh(),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: state.titles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(title: Text(state.titles[index]));
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

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      NotificationsStatus.idle => 'Idle',
      NotificationsStatus.loading => 'Loading',
      NotificationsStatus.ready => 'Ready',
      NotificationsStatus.error => 'Error',
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
