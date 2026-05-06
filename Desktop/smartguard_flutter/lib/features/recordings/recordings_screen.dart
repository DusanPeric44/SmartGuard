import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/data/stub_recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';
import 'package:smartguard_flutter/features/recordings/viewmodel/recordings_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late final RecordingsViewModel _vm;
  late final RecordingsRepository _repo;

  final _searchController = TextEditingController();
  DateTimeRange? _selectedRange;

  String? _selectedDeviceId;
  RecordingType? _selectedType;
  RecordingStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _repo = _buildRepository();
    _vm = RecordingsViewModel(repository: _repo);
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

  RecordingsRepository _buildRepository() {
    if (AppConfig.enableStubData) {
      return StubRecordingsRepository();
    }
    return StubRecordingsRepository();
  }

  @override
  Widget build(BuildContext context) {
    final caps = AppCapabilities.fromRole(AppScope.of(context).auth.role);
    final page = _vm.page;

    return Column(
      children: [
        _FiltersCard(
          searchController: _searchController,
          selectedDeviceId: _selectedDeviceId,
          selectedRange: _selectedRange,
          selectedStatus: _selectedStatus,
          selectedType: _selectedType,
          onSearchChanged: (v) => _vm.setSearch(v),
          onPickRange: _pickDateRange,
          onDeviceChanged: (v) async {
            _selectedDeviceId = v;
            await _applyFilters();
          },
          onTypeChanged: (v) async {
            _selectedType = v;
            await _applyFilters();
          },
          onStatusChanged: (v) async {
            _selectedStatus = v;
            await _applyFilters();
          },
          onReset: () async {
            _searchController.clear();
            _selectedDeviceId = null;
            _selectedType = null;
            _selectedStatus = null;
            _selectedRange = null;
            await _vm.resetFilters();
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildBody(caps, page),
        ),
      ],
    );
  }

  Widget _buildBody(AppCapabilities caps, PageResult<RecordingRow>? page) {
    if (_vm.isLoading && page == null) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (_vm.errorMessage != null && page == null) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: _vm.errorMessage!,
          onRetry: _vm.load,
        ),
      );
    }
    if (page == null) {
      return const SizedBox.shrink();
    }
    if (page.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nema snimaka za odabrane filtere.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_vm.errorMessage!),
                ),
              ),
            ),
          ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _RecordingsTable(
                rows: page.items,
                sortBy: _vm.query.sortBy,
                sortDir: _vm.query.sortDir,
                rowBusy: _vm.rowBusy,
                canDownload: caps.canDownload,
                canSoftDelete: caps.canManageDevices,
                onSortChanged: (by, dir) => _vm.changeSort(by, dir),
                onDownload: (id) => _downloadRecording(id, caps),
                onSoftDelete: (id) => _confirmSoftDelete(id, caps),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Pager(
          total: page.total,
          page: page.page,
          pageSize: page.pageSize,
          isLoading: _vm.isLoading,
          onPrev: page.page > 1 ? () => _vm.changePage(page.page - 1) : null,
          onNext: (page.page * page.pageSize) < page.total
              ? () => _vm.changePage(page.page + 1)
              : null,
          onPageSizeChanged: (size) => _vm.changePageSize(size),
        ),
      ],
    );
  }

  Future<void> _applyFilters() async {
    await _vm.applyFilters(
      deviceId: _selectedDeviceId,
      type: _selectedType,
      status: _selectedStatus,
      from: _selectedRange?.start,
      to: _selectedRange?.end,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _selectedRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
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

  Future<void> _confirmSoftDelete(String id, AppCapabilities caps) async {
    if (!caps.canManageDevices) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemate dozvolu za brisanje snimaka.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft delete'),
        content: Text('Obrisati snimak $id? Snimak će biti označen kao obrisan.'),
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

    await _vm.softDelete(id);
    if (!mounted) return;
    if (_vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snimak $id je obrisan.')),
      );
    }
  }

  Future<void> _downloadRecording(String id, AppCapabilities caps) async {
    if (!caps.canDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemate dozvolu za download snimaka.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Download'),
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
              Expanded(child: Text('Preuzimam snimak...')),
            ],
          ),
        ),
      ),
    );

    final bytes = await _vm.download(id);
    if (mounted) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download nije uspio.')),
      );
      return;
    }

    final filePath = await _writeToTemp(id, bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snimak sačuvan: $filePath')),
    );
  }

  Future<String> _writeToTemp(String id, Uint8List bytes) async {
    final dir = Directory.systemTemp.createTempSync('smartguard_recordings_');
    final file = File('${dir.path}/$id.bin');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.selectedDeviceId,
    required this.selectedRange,
    required this.selectedType,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onPickRange,
    required this.onDeviceChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final String? selectedDeviceId;
  final DateTimeRange? selectedRange;
  final RecordingType? selectedType;
  final RecordingStatus? selectedStatus;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final ValueChanged<String?> onDeviceChanged;
  final ValueChanged<RecordingType?> onTypeChanged;
  final ValueChanged<RecordingStatus?> onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Device ili ID snimka...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedDeviceId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All devices'),
                  ),
                  for (final d in _stubDevices)
                    DropdownMenuItem<String?>(
                      value: d.id,
                      child: Text(d.name),
                    ),
                ],
                onChanged: onDeviceChanged,
                decoration: const InputDecoration(labelText: 'Device'),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<RecordingType?>(
                initialValue: selectedType,
                items: const [
                  DropdownMenuItem<RecordingType?>(
                    value: null,
                    child: Text('All types'),
                  ),
                  DropdownMenuItem(value: RecordingType.motion, child: Text('Motion')),
                  DropdownMenuItem(value: RecordingType.manual, child: Text('Manual')),
                  DropdownMenuItem(value: RecordingType.alarm, child: Text('Alarm')),
                ],
                onChanged: onTypeChanged,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<RecordingStatus?>(
                initialValue: selectedStatus,
                items: const [
                  DropdownMenuItem<RecordingStatus?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  DropdownMenuItem(value: RecordingStatus.available, child: Text('Available')),
                  DropdownMenuItem(value: RecordingStatus.processing, child: Text('Processing')),
                  DropdownMenuItem(value: RecordingStatus.failed, child: Text('Failed')),
                  DropdownMenuItem(value: RecordingStatus.deleted, child: Text('Deleted')),
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
              label: Text(
                'Reset',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _rangeLabel(DateTimeRange? range) {
    if (range == null) return null;
    final s = _yyyyMmDd(range.start);
    final e = _yyyyMmDd(range.end);
    return '$s → $e';
  }
}

class _RecordingsTable extends StatefulWidget {
  const _RecordingsTable({
    required this.rows,
    required this.sortBy,
    required this.sortDir,
    required this.rowBusy,
    required this.canDownload,
    required this.canSoftDelete,
    required this.onSortChanged,
    required this.onDownload,
    required this.onSoftDelete,
  });

  final List<RecordingRow> rows;
  final RecordingsSortBy sortBy;
  final SortDir sortDir;
  final Map<String, bool> rowBusy;
  final bool canDownload;
  final bool canSoftDelete;
  final void Function(RecordingsSortBy by, SortDir dir) onSortChanged;
  final ValueChanged<String> onDownload;
  final ValueChanged<String> onSoftDelete;

  @override
  State<_RecordingsTable> createState() => _RecordingsTableState();
}

class _RecordingsTableState extends State<_RecordingsTable> {
  @override
  Widget build(BuildContext context) {
    final sortAscending = widget.sortDir == SortDir.asc;
    return SingleChildScrollView(
      child: DataTable(
        sortAscending: sortAscending,
        sortColumnIndex: _sortIndex(widget.sortBy),
        columns: [
          DataColumn(
            label: const Text('Timestamp'),
            onSort: (_, asc) => widget.onSortChanged(
              RecordingsSortBy.startedAt,
              asc ? SortDir.asc : SortDir.desc,
            ),
          ),
          DataColumn(
            label: const Text('Device'),
            onSort: (_, asc) => widget.onSortChanged(
              RecordingsSortBy.deviceName,
              asc ? SortDir.asc : SortDir.desc,
            ),
          ),
          const DataColumn(label: Text('Type')),
          DataColumn(
            label: const Text('Status'),
            onSort: (_, asc) => widget.onSortChanged(
              RecordingsSortBy.status,
              asc ? SortDir.asc : SortDir.desc,
            ),
          ),
          DataColumn(
            numeric: true,
            label: const Text('Duration'),
            onSort: (_, asc) => widget.onSortChanged(
              RecordingsSortBy.durationSeconds,
              asc ? SortDir.asc : SortDir.desc,
            ),
          ),
          DataColumn(
            numeric: true,
            label: const Text('Size'),
            onSort: (_, asc) => widget.onSortChanged(
              RecordingsSortBy.sizeBytes,
              asc ? SortDir.asc : SortDir.desc,
            ),
          ),
          const DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final r in widget.rows) _row(context, r),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, RecordingRow r) {
    final busy = widget.rowBusy[r.id] == true;
    final statusChip = _StatusChip(status: r.status);
    final canDownload = widget.canDownload && r.status == RecordingStatus.available && !busy;
    final canDelete = widget.canSoftDelete && r.status != RecordingStatus.deleted && !busy;

    return DataRow(
      cells: [
        DataCell(Text('${_yyyyMmDd(r.startedAt)} ${_hhMm(r.startedAt)}')),
        DataCell(Text(r.deviceName)),
        DataCell(Text(_typeLabel(r.type))),
        DataCell(statusChip),
        DataCell(Text(_durationLabel(r.durationSeconds))),
        DataCell(Text(_bytesLabel(r.sizeBytes))),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: widget.canDownload ? 'Download' : 'Nema dozvolu',
                onPressed: canDownload ? () => widget.onDownload(r.id) : null,
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton(
                tooltip: widget.canSoftDelete ? 'Soft delete' : 'Nema dozvolu',
                onPressed: canDelete ? () => widget.onSoftDelete(r.id) : null,
                icon: const Icon(Icons.delete_outline),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  int? _sortIndex(RecordingsSortBy by) {
    switch (by) {
      case RecordingsSortBy.startedAt:
        return 0;
      case RecordingsSortBy.deviceName:
        return 1;
      case RecordingsSortBy.status:
        return 3;
      case RecordingsSortBy.durationSeconds:
        return 4;
      case RecordingsSortBy.sizeBytes:
        return 5;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RecordingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label),
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
            onChanged: isLoading ? null : (v) => v == null ? null : onPageSizeChanged(v),
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

String _durationLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m}m ${s}s';
}

String _bytesLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024.0;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024.0;
  return '${gb.toStringAsFixed(2)} GB';
}

String _typeLabel(RecordingType type) {
  switch (type) {
    case RecordingType.motion:
      return 'Motion';
    case RecordingType.manual:
      return 'Manual';
    case RecordingType.alarm:
      return 'Alarm';
  }
}

String _statusLabel(RecordingStatus status) {
  switch (status) {
    case RecordingStatus.available:
      return 'Available';
    case RecordingStatus.processing:
      return 'Processing';
    case RecordingStatus.failed:
      return 'Failed';
    case RecordingStatus.deleted:
      return 'Deleted';
  }
}

Color _statusColor(BuildContext context, RecordingStatus status) {
  switch (status) {
    case RecordingStatus.available:
      return Colors.greenAccent.shade400;
    case RecordingStatus.processing:
      return Colors.amberAccent.shade400;
    case RecordingStatus.failed:
      return Theme.of(context).colorScheme.error;
    case RecordingStatus.deleted:
      return Colors.blueGrey.shade300;
  }
}

const _stubDevices = <({String id, String name})>[
  (id: 'dev-1', name: 'Camera 01'),
  (id: 'dev-2', name: 'Camera 02'),
  (id: 'dev-3', name: 'Camera 03'),
  (id: 'dev-4', name: 'Camera 04'),
  (id: 'dev-5', name: 'Camera 05'),
  (id: 'dev-6', name: 'Camera 06'),
  (id: 'dev-7', name: 'Camera 07'),
  (id: 'dev-8', name: 'Camera 08'),
  (id: 'dev-9', name: 'Camera 09'),
  (id: 'dev-10', name: 'Camera 10'),
  (id: 'dev-11', name: 'Camera 11'),
  (id: 'dev-12', name: 'Camera 12'),
  (id: 'dev-13', name: 'Camera 13'),
  (id: 'dev-14', name: 'Camera 14'),
  (id: 'dev-15', name: 'Camera 15'),
  (id: 'dev-16', name: 'Camera 16'),
  (id: 'dev-17', name: 'Camera 17'),
  (id: 'dev-18', name: 'Camera 18'),
];
