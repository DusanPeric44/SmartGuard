import 'package:flutter/material.dart';

/// Search + refresh + add row above the reference-data table.
class ReferenceFiltersCard extends StatelessWidget {
  const ReferenceFiltersCard({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.addLabel,
    this.onAdd,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Name...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            Tooltip(
              message: onAdd == null
                  ? 'Unavailable for your role'
                  : '',
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
