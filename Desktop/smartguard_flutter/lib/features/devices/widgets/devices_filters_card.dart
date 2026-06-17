import 'package:flutter/material.dart';

class DevicesFiltersCard extends StatelessWidget {
  const DevicesFiltersCard({
    super.key,
    required this.statusName,
    required this.onStatusChanged,
    required this.onRefresh,
    this.onAddDevice,
  });

  final String? statusName;
  final ValueChanged<String?> onStatusChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddDevice;

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
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: statusName,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('All')),
                  DropdownMenuItem<String?>(
                    value: 'Online',
                    child: Text('Online'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Offline',
                    child: Text('Offline'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Maintenance',
                    child: Text('Maintenance'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (onAddDevice != null)
              FilledButton.icon(
                onPressed: onAddDevice,
                icon: const Icon(Icons.add),
                label: const Text('Add New Device'),
              ),
          ],
        ),
      ),
    );
  }
}
