import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/data/stub_reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';
import 'package:smartguard_flutter/features/reference_data/viewmodel/reference_data_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen> {
  late final ReferenceDataViewModel _vm;
  late final ReferenceDataRepository _repo;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = _buildRepository();
    _vm = ReferenceDataViewModel(
      repository: _repo,
      entities: const [
        ReferenceEntityConfig(key: 'device_types', label: 'Device Types'),
        ReferenceEntityConfig(key: 'alarm_categories', label: 'Alarm Categories'),
        ReferenceEntityConfig(key: 'zones', label: 'Zones'),
      ],
    );
    _vm.addListener(_onVmChanged);
    _vm.init();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  ReferenceDataRepository _buildRepository() {
    if (AppConfig.enableStubData) {
      return StubReferenceDataRepository();
    }
    return StubReferenceDataRepository();
  }

  @override
  Widget build(BuildContext context) {
    final caps = AppCapabilities.fromRole(AppScope.of(context).auth.role);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: _vm.selectedEntityKey.isEmpty ? null : _vm.selectedEntityKey,
                    items: [
                      for (final e in _vm.entities)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(e.label),
                        ),
                    ],
                    onChanged: _vm.isLoading
                        ? null
                        : (v) {
                            if (v == null) return;
                            _searchController.clear();
                            _vm.selectEntity(v);
                          },
                    decoration: const InputDecoration(labelText: 'Entity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _vm.setSearch,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: (!caps.canEditReferenceData || _vm.isLoading)
                      ? null
                      : () => _openEditor(context, caps, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildBody(context, caps),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppCapabilities caps) {
    if (_vm.isLoading && _vm.items.isEmpty) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (_vm.errorMessage != null && _vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: _vm.errorMessage!,
          onRetry: _vm.load,
        ),
      );
    }
    if (_vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nema podataka za ovu šifarniku.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Active')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final it in _vm.items)
                DataRow(
                  cells: [
                    DataCell(Text(it.code)),
                    DataCell(Text(it.name)),
                    DataCell(Icon(it.isActive ? Icons.check : Icons.close)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: caps.canEditReferenceData ? 'Edit' : 'Nema dozvolu',
                            onPressed: (!caps.canEditReferenceData || _vm.isLoading)
                                ? null
                                : () => _openEditor(context, caps, it),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: caps.canEditReferenceData ? 'Delete' : 'Nema dozvolu',
                            onPressed: (!caps.canEditReferenceData || _vm.isLoading)
                                ? null
                                : () => _confirmDelete(context, it),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReferenceItem it) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Obrisati "${it.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await _vm.delete(it.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(success ? 'Obrisano.' : (_vm.errorMessage ?? 'Greška.'))),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppCapabilities caps,
    ReferenceItem? existing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<ReferenceItem>(
      context: context,
      builder: (context) => _ReferenceEditorDialog(existing: existing),
    );
    if (res == null) return;
    final saved = await _vm.createOrUpdate(res);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(saved != null ? 'Sačuvano.' : (_vm.errorMessage ?? 'Greška.')),
      ),
    );
  }
}

class _ReferenceEditorDialog extends StatefulWidget {
  const _ReferenceEditorDialog({
    required this.existing,
  });

  final ReferenceItem? existing;

  @override
  State<_ReferenceEditorDialog> createState() => _ReferenceEditorDialogState();
}

class _ReferenceEditorDialogState extends State<_ReferenceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.existing?.code ?? '');
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _active = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit item' : 'Create item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Code je obavezan.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Name je obavezan.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final draft = ReferenceItem(
              id: widget.existing?.id ?? '',
              code: _code.text.trim(),
              name: _name.text.trim(),
              isActive: _active,
            );
            Navigator.of(context).pop(draft);
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
