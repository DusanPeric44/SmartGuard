import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/known_persons_controller.dart';
import '../application/known_persons_state.dart';

class KnownPersonsScreen extends ConsumerWidget {
  const KnownPersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(knownPersonsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Known Persons (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == KnownPersonsStatus.loading
                  ? null
                  : () => ref
                        .read(knownPersonsControllerProvider.notifier)
                        .refresh(),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: state.names.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(title: Text(state.names[index]));
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

  final KnownPersonsState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      KnownPersonsStatus.idle => 'Idle',
      KnownPersonsStatus.loading => 'Loading',
      KnownPersonsStatus.ready => 'Ready',
      KnownPersonsStatus.error => 'Error',
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
