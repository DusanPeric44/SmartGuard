import 'package:flutter/material.dart';

class AlarmDismissDialog extends StatefulWidget {
  const AlarmDismissDialog({super.key});

  @override
  State<AlarmDismissDialog> createState() => _AlarmDismissDialogState();
}

class _AlarmDismissDialogState extends State<AlarmDismissDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text.trim();
    return AlertDialog(
      title: const Text('Dismiss alarm'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Dismissal reason'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: value.isEmpty
              ? null
              : () => Navigator.of(context).pop(value),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
