import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/feature_template_controller.dart';
import '../application/feature_template_state.dart';

class FeatureTemplateScreen extends ConsumerWidget {
  const FeatureTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureTemplateControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Template (example)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _StatusLine(state: state),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.status == FeatureTemplateStatus.loading
                  ? null
                  : () => ref
                      .read(featureTemplateControllerProvider.notifier)
                      .refresh(),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: state.itemTitles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(title: Text(state.itemTitles[index]));
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

  final FeatureTemplateState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      FeatureTemplateStatus.idle => 'Idle',
      FeatureTemplateStatus.loading => 'Loading',
      FeatureTemplateStatus.ready => 'Ready',
      FeatureTemplateStatus.error => 'Error',
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

