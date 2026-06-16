import 'package:flutter/material.dart';

class AlarmsDismissDialog extends StatefulWidget {
  const AlarmsDismissDialog({super.key});

  @override
  State<AlarmsDismissDialog> createState() => _AlarmsDismissDialogState();
}

class _AlarmsDismissDialogState extends State<AlarmsDismissDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dismiss alert'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Dismissal reason',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final t = _controller.text.trim();
            if (t.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dismissal reason is required.')),
              );
              return;
            }
            Navigator.of(context).pop(t);
          },
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
