import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/audit_logs/data/api_audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/data/audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/viewmodel/audit_logs_view_model.dart';
import 'package:smartguard_flutter/features/audit_logs/widgets/audit_logs_filters_card.dart';
import 'package:smartguard_flutter/features/audit_logs/widgets/audit_logs_pager.dart';
import 'package:smartguard_flutter/features/audit_logs/widgets/audit_logs_table.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  AuditLogsRepository? _repo;
  AuditLogsViewModel? _vm;

  final _searchController = TextEditingController();
  DateTimeRange? _selectedRange;

  String? _selectedUser;
  String? _selectedAction;
  String? _selectedResource;
  String? _selectedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiAuditLogsRepository(api: AppScope.of(context).api);
    _vm = AuditLogsViewModel(repository: _repo!);
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
    if (vm == null) return const Center(child: AsyncStatePanel.loading());

    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Logs', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Search and review system audit events',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AuditLogsFiltersCard(
          searchController: _searchController,
          selectedRange: _selectedRange,
          selectedUser: _selectedUser,
          selectedAction: _selectedAction,
          selectedResource: _selectedResource,
          selectedStatus: _selectedStatus,
          userOptions: vm.userOptions,
          actionOptions: vm.actionOptions,
          resourceOptions: vm.resourceOptions,
          statusOptions: vm.statusOptions,
          onSearchChanged: vm.setSearch,
          onPickRange: _pickDateRange,
          onUserChanged: (v) async {
            _selectedUser = v;
            await _applyFilters();
          },
          onActionChanged: (v) async {
            _selectedAction = v;
            await _applyFilters();
          },
          onResourceChanged: (v) async {
            _selectedResource = v;
            await _applyFilters();
          },
          onStatusChanged: (v) async {
            _selectedStatus = v;
            await _applyFilters();
          },
          onReset: () async {
            _searchController.clear();
            _selectedUser = null;
            _selectedAction = null;
            _selectedResource = null;
            _selectedStatus = null;
            _selectedRange = null;
            vm.setSearch('');
            await vm.resetFilters();
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm)),
      ],
    );
  }

  Widget _buildBody(AuditLogsViewModel vm) {
    final page = vm.page;
    if (vm.isLoading && page == null) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && page == null) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (page == null) return const SizedBox.shrink();
    if (page.result.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No audit logs for selected filters.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final q = vm.query;
    return Column(
      children: [
        if (vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vm.errorMessage!),
                ),
              ),
            ),
          ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AuditLogsTable(
                rows: page.result,
                rowBusy: vm.rowBusy,
                onOpenDetails: (row) => _openDetails(vm, row),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AuditLogsPager(
          total: page.count,
          page: q.page,
          pageSize: q.pageSize,
          isLoading: vm.isLoading,
          onPrev: q.page > 1 ? () => vm.changePage(q.page - 1) : null,
          onNext: (q.page * q.pageSize) < page.count
              ? () => vm.changePage(q.page + 1)
              : null,
          onPageSizeChanged: (size) => vm.changePageSize(size),
        ),
      ],
    );
  }

  Future<void> _applyFilters() async {
    final vm = _vm;
    if (vm == null) return;
    await vm.applyFilters(
      userId: _selectedUser,
      action: _selectedAction,
      resource: _selectedResource,
      status: _selectedStatus,
      from: _selectedRange?.start,
      to: _selectedRange?.end,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _selectedRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked == null) return;
    setState(() => _selectedRange = picked);
    await _applyFilters();
  }

  Future<void> _openDetails(AuditLogsViewModel vm, AuditLogRow row) async {
    if (row.id <= 0) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Audit Log'),
        content: SizedBox(
          width: 360,
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Loading details...')),
            ],
          ),
        ),
      ),
    );

    AuditLogDetails? details;
    try {
      details = await vm.loadDetails(row.id);
    } finally {
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
    if (!mounted) return;
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Failed to load details.')),
      );
      return;
    }

    final d = details;
    final entries = d.raw.entries.toList(growable: false)
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text('Audit Log #${d.id}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            _valueLabel(e.value),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

String _valueLabel(Object? value) {
  if (value == null) return '-';
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }
  if (value is num || value is bool) return value.toString();
  if (value is Map || value is List) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
  return value.toString();
}
