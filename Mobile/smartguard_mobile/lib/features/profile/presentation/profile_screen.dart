import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/profile_controller.dart';
import '../application/profile_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Profile (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            Text('Display name: ${state.displayName ?? '-'}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == ProfileStatus.loading
                  ? null
                  : () =>
                        ref.read(profileControllerProvider.notifier).refresh(),
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

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      ProfileStatus.idle => 'Idle',
      ProfileStatus.loading => 'Loading',
      ProfileStatus.ready => 'Ready',
      ProfileStatus.error => 'Error',
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
