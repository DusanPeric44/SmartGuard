import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';
import 'package:smartguard_flutter/features/reference_data/viewmodel/reference_data_view_model.dart';

/// Create/edit dialog for a reference record. Validation messages are shown
/// inline beneath the fields (not as snackbars/dialogs).
class ReferenceUpsertDialog extends StatefulWidget {
  const ReferenceUpsertDialog({super.key, required this.vm, this.item});

  final ReferenceDataViewModel vm;
  final ReferenceItem? item;

  @override
  State<ReferenceUpsertDialog> createState() => _ReferenceUpsertDialogState();
}

class _ReferenceUpsertDialogState extends State<ReferenceUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _countryId;

  bool get _isEdit => widget.item != null;
  bool get _hasCountry => widget.vm.entity.hasCountry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _countryId = widget.item?.countryId;
    if (_hasCountry && _countryId == null && widget.vm.countries.isNotEmpty) {
      _countryId = widget.vm.countries.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final ok = _isEdit
        ? await widget.vm.update(
            widget.item!.id,
            name: name,
            countryId: _hasCountry ? _countryId : null,
          )
        : await widget.vm.create(
            name: name,
            countryId: _hasCountry ? _countryId : null,
          );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
    // On failure the backend message is surfaced inline via vm.errorMessage.
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.vm.entity;
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final busy = _isEdit
            ? widget.vm.rowBusy[widget.item!.id] == true
            : widget.vm.isLoading;
        final backendError = widget.vm.errorMessage;
        return AlertDialog(
          title: Text('${_isEdit ? 'Edit' : 'Add'} ${entity.singular}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !busy,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Name is required.';
                      if (v.length > 100) {
                        return 'Name must be at most 100 characters.';
                      }
                      return null;
                    },
                  ),
                  if (_hasCountry) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _countryId,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final country in widget.vm.countries)
                          DropdownMenuItem<int>(
                            value: country.id,
                            child: Text(country.name),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => setState(() => _countryId = value),
                      validator: (value) =>
                          value == null ? 'Please select a country.' : null,
                    ),
                  ],
                  if (backendError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      backendError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
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
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }
}
