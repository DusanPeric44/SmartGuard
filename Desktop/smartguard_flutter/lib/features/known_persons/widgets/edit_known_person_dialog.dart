import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/viewmodel/known_persons_view_model.dart';

class EditKnownPersonDialog extends StatefulWidget {
  const EditKnownPersonDialog({
    super.key,
    required this.vm,
    required this.person,
  });

  final KnownPersonsViewModel vm;
  final KnownPerson person;

  @override
  State<EditKnownPersonDialog> createState() => _EditKnownPersonDialogState();
}

class _EditKnownPersonDialogState extends State<EditKnownPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first = TextEditingController(
    text: widget.person.firstName,
  );
  late final TextEditingController _last = TextEditingController(
    text: widget.person.lastName,
  );

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'This field is required.' : null;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final busy = widget.vm.rowBusy[widget.person.id] == true;
        return AlertDialog(
          title: const Text('Edit person'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _first,
                    enabled: !busy,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _last,
                    enabled: !busy,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Last name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final f = _first.text.trim();
                      final l = _last.text.trim();
                      final ok = await widget.vm.updatePerson(
                        id: widget.person.id,
                        firstName: f,
                        lastName: l,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.vm.errorMessage ?? 'Error.'),
                          ),
                        );
                      }
                    },
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
