import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddKnownPersonResult {
  const AddKnownPersonResult({
    required this.firstName,
    required this.lastName,
    this.photoBytes,
    this.photoFileName,
  });

  final String firstName;
  final String lastName;
  final Uint8List? photoBytes;
  final String? photoFileName;
}

class AddKnownPersonDialog extends StatefulWidget {
  const AddKnownPersonDialog({super.key});

  @override
  State<AddKnownPersonDialog> createState() => _AddKnownPersonDialogState();
}

class _AddKnownPersonDialogState extends State<AddKnownPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoFileName;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoFileName = picked.name;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      AddKnownPersonResult(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        photoBytes: _photoBytes,
        photoFileName: _photoFileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add known person'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _photoBytes != null
                      ? MemoryImage(_photoBytes!)
                      : null,
                  child: _photoBytes == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 28)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
