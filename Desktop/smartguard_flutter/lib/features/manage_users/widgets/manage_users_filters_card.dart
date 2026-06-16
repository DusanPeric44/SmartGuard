import 'package:flutter/material.dart';

class ManageUsersFiltersCard extends StatelessWidget {
  const ManageUsersFiltersCard({
    super.key,
    required this.controller,
    required this.onTermChanged,
    required this.onRefresh,
    this.onAddUser,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTermChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddUser;

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
                onChanged: onTermChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Email...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (onAddUser != null)
              FilledButton.icon(
                onPressed: onAddUser,
                icon: const Icon(Icons.add),
                label: const Text('Add user'),
              ),
          ],
        ),
      ),
    );
  }
}
