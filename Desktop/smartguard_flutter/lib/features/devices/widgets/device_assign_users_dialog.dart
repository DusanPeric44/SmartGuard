import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class DeviceAssignUsersDialog extends StatefulWidget {
  const DeviceAssignUsersDialog({
    super.key,
    required this.allUsers,
    required this.selected,
  });

  final List<DeviceUser> allUsers;
  final Set<String> selected;

  @override
  State<DeviceAssignUsersDialog> createState() =>
      _DeviceAssignUsersDialogState();
}

class _DeviceAssignUsersDialogState extends State<DeviceAssignUsersDialog> {
  late final Set<String> _selected = Set<String>.from(widget.selected);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.allUsers
        : widget.allUsers
              .where((u) => u.email.toLowerCase().contains(q))
              .toList(growable: false);

    return AlertDialog(
      title: const Text('Assign users'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final u = filtered[index];
                  final selected = _selected.contains(u.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(u.id);
                        } else {
                          _selected.remove(u.id);
                        }
                      });
                    },
                    title: Text(u.email),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
