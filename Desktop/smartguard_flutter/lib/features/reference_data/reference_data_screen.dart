import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/features/reference_data/data/api_reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';
import 'package:smartguard_flutter/features/reference_data/viewmodel/reference_data_view_model.dart';
import 'package:smartguard_flutter/features/reference_data/widgets/reference_entity_selector.dart';
import 'package:smartguard_flutter/features/reference_data/widgets/reference_filters_card.dart';
import 'package:smartguard_flutter/features/reference_data/widgets/reference_upsert_dialog.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen> {
  ReferenceDataRepository? _repo;
  ReferenceDataViewModel? _vm;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;
    _repo = ApiReferenceDataRepository(api: AppScope.of(context).api);
    _vm = ReferenceDataViewModel(repository: _repo!);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) {
      return const Center(child: AsyncStatePanel.loading());
    }

    final caps = AppCapabilities.fromRole(AppScope.of(context).auth.role);
    final canEdit = caps.canEditReferenceData;

    return Column(
      children: [
        ReferenceEntitySelector(
          selected: vm.entity,
          enabled: !vm.isLoading,
          onSelected: (entity) {
            _searchController.clear();
            vm.selectEntity(entity);
          },
        ),
        const SizedBox(height: 12),
        ReferenceFiltersCard(
          controller: _searchController,
          onSearchChanged: vm.setSearch,
          onRefresh: vm.load,
          addLabel: 'Add ${vm.entity.singular}',
          onAdd: canEdit ? () => _openUpsert(vm) : null,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm: vm, canEdit: canEdit)),
      ],
    );
  }

  Widget _buildBody({
    required ReferenceDataViewModel vm,
    required bool canEdit,
  }) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No ${vm.entity.title.toLowerCase()}.',
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
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final item in vm.items)
                DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(_actions(vm: vm, item: item, canEdit: canEdit)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions({
    required ReferenceDataViewModel vm,
    required ReferenceItem item,
    required bool canEdit,
  }) {
    final busy = vm.rowBusy[item.id] == true;
    final disabledReason = !canEdit
        ? 'Unavailable for your role'
        : (busy ? 'Action in progress…' : '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: disabledReason.isEmpty ? 'Edit' : disabledReason,
          child: IconButton(
            onPressed: (!canEdit || busy) ? null : () => _openUpsert(vm, item: item),
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        Tooltip(
          message: disabledReason.isEmpty ? 'Delete' : disabledReason,
          child: IconButton(
            onPressed: (!canEdit || busy) ? null : () => _confirmDelete(vm, item),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        if (busy)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Future<void> _openUpsert(
    ReferenceDataViewModel vm, {
    ReferenceItem? item,
  }) async {
    final singular = vm.entity.singular;
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReferenceUpsertDialog(vm: vm, item: item),
    );
    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? '$singular created.' : '$singular updated.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    ReferenceDataViewModel vm,
    ReferenceItem item,
  ) async {
    final singular = vm.entity.singular;
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $singular'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (res != true) return;

    final ok = await vm.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '$singular deleted.' : (vm.errorMessage ?? 'Could not delete.'),
        ),
      ),
    );
  }
}
