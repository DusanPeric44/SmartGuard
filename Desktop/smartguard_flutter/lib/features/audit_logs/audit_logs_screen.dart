import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/audit_logs/data/api_audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/data/audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/viewmodel/audit_logs_view_model.dart';
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
        _FiltersCard(
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
              child: _AuditLogsTable(
                rows: page.result,
                rowBusy: vm.rowBusy,
                onOpenDetails: (row) => _openDetails(vm, row),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Pager(
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

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.selectedRange,
    required this.selectedUser,
    required this.selectedAction,
    required this.selectedResource,
    required this.selectedStatus,
    required this.userOptions,
    required this.actionOptions,
    required this.resourceOptions,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onPickRange,
    required this.onUserChanged,
    required this.onActionChanged,
    required this.onResourceChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final DateTimeRange? selectedRange;

  final String? selectedUser;
  final String? selectedAction;
  final String? selectedResource;
  final String? selectedStatus;

  final List<String> userOptions;
  final List<String> actionOptions;
  final List<String> resourceOptions;
  final List<String> statusOptions;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onResourceChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _optionsWithSelected(userOptions, selectedUser);
    final actions = _optionsWithSelected(actionOptions, selectedAction);
    final resources = _optionsWithSelected(resourceOptions, selectedResource);
    final statuses = _optionsWithSelected(statusOptions, selectedStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 500,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Text...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedUser,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All users'),
                  ),
                  for (final u in users)
                    DropdownMenuItem<String?>(
                      value: u,
                      child: Text(
                        u,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onUserChanged,
                decoration: const InputDecoration(labelText: 'User'),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedAction,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All actions'),
                  ),
                  for (final a in actions)
                    DropdownMenuItem<String?>(
                      value: a,
                      child: Text(
                        a,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onActionChanged,
                decoration: const InputDecoration(labelText: 'Action'),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedResource,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All resources'),
                  ),
                  for (final r in resources)
                    DropdownMenuItem<String?>(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onResourceChanged,
                decoration: const InputDecoration(labelText: 'Resource'),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedStatus,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  for (final s in statuses)
                    DropdownMenuItem<String?>(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onStatusChanged,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onPickRange,
              icon: const Icon(Icons.date_range),
              label: Text(_rangeLabel(selectedRange) ?? 'Date range'),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: Text('Reset', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogsTable extends StatelessWidget {
  const _AuditLogsTable({
    required this.rows,
    required this.rowBusy,
    required this.onOpenDetails,
  });

  final List<AuditLogRow> rows;
  final Map<String, bool> rowBusy;
  final ValueChanged<AuditLogRow> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Resource')),
            DataColumn(label: Text('Details')),
            DataColumn(label: Text('IP')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: [for (final r in rows) _row(context, r)],
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, AuditLogRow r) {
    final key = r.id.toString();
    final busy = rowBusy[key] == true;
    return DataRow(
      cells: [
        DataCell(Text(_timestampLabel(r.timestamp))),
        DataCell(Text(r.user)),
        DataCell(Text(r.action)),
        DataCell(Text(r.resource)),
        DataCell(
          SizedBox(
            width: 360,
            child: Text(
              r.details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(r.ipAddress)),
        DataCell(Text(r.status)),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: 'Details',
                onPressed: busy ? null : () => onOpenDetails(r),
                icon: busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  final int total;
  final int page;
  final int pageSize;
  final bool isLoading;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = (page * pageSize).clamp(0, total);
    return Row(
      children: [
        Text('Showing $start-$end of $total'),
        const Spacer(),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int>(
            initialValue: pageSize,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10 / page')),
              DropdownMenuItem(value: 25, child: Text('25 / page')),
              DropdownMenuItem(value: 50, child: Text('50 / page')),
              DropdownMenuItem(value: 100, child: Text('100 / page')),
            ],
            onChanged: isLoading
                ? null
                : (v) => v == null ? null : onPageSizeChanged(v),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous',
          onPressed: isLoading ? null : onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page'),
        IconButton(
          tooltip: 'Next',
          onPressed: isLoading ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

String? _rangeLabel(DateTimeRange? range) {
  if (range == null) return null;
  final s = _yyyyMmDd(range.start);
  final e = _yyyyMmDd(range.end);
  return '$s → $e';
}

String _timestampLabel(DateTime? dt) {
  if (dt == null) return '-';
  return '${_yyyyMmDd(dt)} ${_hhMm(dt)}';
}

String _yyyyMmDd(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _hhMm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
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

List<String> _optionsWithSelected(List<String> options, String? selected) {
  final s = selected?.trim();
  if (s == null || s.isEmpty) return options;
  if (options.contains(s)) return options;
  return <String>[s, ...options];
}
