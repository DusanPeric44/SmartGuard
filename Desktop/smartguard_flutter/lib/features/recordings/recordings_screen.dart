import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/features/recordings/data/api_recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_device_option.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';
import 'package:smartguard_flutter/features/recordings/viewmodel/recordings_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  RecordingsViewModel? _vm;
  RecordingsRepository? _repo;

  final _searchController = TextEditingController();
  DateTimeRange? _selectedRange;

  int? _selectedDeviceId;
  RecordingType? _selectedType;
  RecordingStatus? _selectedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiRecordingsRepository(api: AppScope.of(context).api);
    _vm = RecordingsViewModel(repository: _repo!);
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
    final caps = AppCapabilities.fromRole(AppScope.of(context).auth.role);
    final vm = _vm;
    if (vm == null) return const Center(child: AsyncStatePanel.loading());
    final page = vm.page;
    final devices = vm.devices;

    return Column(
      children: [
        _FiltersCard(
          searchController: _searchController,
          devices: devices,
          selectedDeviceId: _selectedDeviceId,
          selectedRange: _selectedRange,
          selectedStatus: _selectedStatus,
          selectedType: _selectedType,
          onSearchChanged: (v) => vm.setSearch(v),
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
            await vm.resetFilters();
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm, caps, page)),
      ],
    );
  }

  Widget _buildBody(
    RecordingsViewModel vm,
    AppCapabilities caps,
    PageResult<RecordingRow>? page,
  ) {
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
              child: _RecordingsTable(
                rows: page.items,
                rowBusy: vm.rowBusy,
                canDownload: caps.canDownload,
                canSoftDelete: caps.canManageDevices,
                onDownload: (row) => _downloadRecording(row, caps),
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
          isLoading: vm.isLoading,
          onPrev: page.page > 1 ? () => vm.changePage(page.page - 1) : null,
          onNext: (page.page * page.pageSize) < page.total
              ? () => vm.changePage(page.page + 1)
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
      deviceId: _selectedDeviceId,
      type: _selectedType,
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

  Future<void> _confirmSoftDelete(int id, AppCapabilities caps) async {
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
        content: Text(
          'Obrisati snimak $id? Snimak će biti označen kao obrisan.',
        ),
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

    final vm = _vm;
    if (vm == null) return;
    await vm.softDelete(id);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Snimak $id je obrisan.')));
    }
  }

  Future<void> _downloadRecording(
    RecordingRow row,
    AppCapabilities caps,
  ) async {
    if (!caps.canDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemate dozvolu za download snimaka.')),
      );
      return;
    }
    if (row.fileName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snimak nema fileName za download.')),
      );
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      useRootNavigator: true,
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

    final vm = _vm;
    if (vm == null) return;

    Uint8List? bytes;
    try {
      bytes = await vm.download(row.id.toString(), row.fileName);
    } finally {
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download nije uspio.')));
      return;
    }

    final filePath = await _saveAs(row.fileName, bytes);
    if (!mounted) return;
    if (filePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download otkazan.')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Snimak sačuvan: $filePath')));
  }

  Future<String?> _saveAs(String fileName, Uint8List bytes) async {
    final safeName = fileName.split('/').last.trim();
    final finalName = safeName.isEmpty ? 'recording.bin' : safeName;
    final location = await getSaveLocation(suggestedName: finalName);
    if (location == null) return null;
    if (location.path.trim().isEmpty) return null;
    final file = File(location.path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.devices,
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
  final List<RecordingDeviceOption> devices;
  final int? selectedDeviceId;
  final DateTimeRange? selectedRange;
  final RecordingType? selectedType;
  final RecordingStatus? selectedStatus;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final ValueChanged<int?> onDeviceChanged;
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
              width: 500,
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
              width: 500,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedDeviceId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All devices'),
                  ),
                  for (final d in devices)
                    DropdownMenuItem<int>(
                      value: d.id,
                      child: Text(
                        d.name,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
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
                  DropdownMenuItem(
                    value: RecordingType.motion,
                    child: Text('Motion'),
                  ),
                  DropdownMenuItem(
                    value: RecordingType.manual,
                    child: Text('Manual'),
                  ),
                  DropdownMenuItem(
                    value: RecordingType.faceDetected,
                    child: Text('Face Detected'),
                  ),
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
                  DropdownMenuItem(
                    value: RecordingStatus.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.uploading,
                    child: Text('Uploading'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.uploading,
                    child: Text('Uploading'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.failed,
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.archived,
                    child: Text('Archived'),
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

  String? _rangeLabel(DateTimeRange? range) {
    if (range == null) return null;
    final s = _yyyyMmDd(range.start);
    final e = _yyyyMmDd(range.end);
    return '$s → $e';
  }
}

class _RecordingsTable extends StatelessWidget {
  const _RecordingsTable({
    required this.rows,
    required this.rowBusy,
    required this.canDownload,
    required this.canSoftDelete,
    required this.onDownload,
    required this.onSoftDelete,
  });

  final List<RecordingRow> rows;
  final Map<String, bool> rowBusy;
  final bool canDownload;
  final bool canSoftDelete;
  final ValueChanged<RecordingRow> onDownload;
  final ValueChanged<int> onSoftDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Timestamp')),
          const DataColumn(label: Text('Device')),
          const DataColumn(label: Text('Type')),
          const DataColumn(label: Text('Status')),
          const DataColumn(numeric: true, label: Text('Duration')),
          const DataColumn(numeric: true, label: Text('Size')),
          const DataColumn(label: Text('Actions')),
        ],
        rows: [for (final r in rows) _row(context, r)],
      ),
    );
  }

  DataRow _row(BuildContext context, RecordingRow r) {
    final key = r.id.toString();
    final busy = rowBusy[key] == true;
    final statusChip = _StatusChip(status: r.status);
    final canDownloadNow = canDownload && !busy;
    final canDeleteNow = canSoftDelete && !busy;
    final deviceLabel = r.deviceName.trim().isNotEmpty
        ? r.deviceName
        : 'Device ${r.deviceId}';

    return DataRow(
      cells: [
        DataCell(Text('${_yyyyMmDd(r.startedAt)} ${_hhMm(r.startedAt)}')),
        DataCell(Text(deviceLabel)),
        DataCell(Text(_typeLabel(r.type))),
        DataCell(statusChip),
        DataCell(Text(_durationLabel(r.durationSeconds))),
        DataCell(Text(_bytesLabel(r.sizeBytes))),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: canDownload ? 'Download' : 'Nema dozvolu',
                onPressed: canDownloadNow ? () => onDownload(r) : null,
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton(
                tooltip: canSoftDelete ? 'Soft delete' : 'Nema dozvolu',
                onPressed: canDeleteNow ? () => onSoftDelete(r.id) : null,
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
    case RecordingType.faceDetected:
      return 'Face Detected';
  }
}

String _statusLabel(RecordingStatus status) {
  switch (status) {
    case RecordingStatus.completed:
      return 'Completed';
    case RecordingStatus.pending:
      return 'Pending';
    case RecordingStatus.uploading:
      return 'Uploading';
    case RecordingStatus.failed:
      return 'Failed';
    case RecordingStatus.archived:
      return 'Archived';
  }
}

Color _statusColor(BuildContext context, RecordingStatus status) {
  switch (status) {
    case RecordingStatus.uploading:
      return Colors.blueAccent.shade400;
    case RecordingStatus.completed:
      return Colors.greenAccent.shade400;
    case RecordingStatus.pending:
      return Colors.amberAccent.shade400;
    case RecordingStatus.failed:
      return Theme.of(context).colorScheme.error;
    case RecordingStatus.archived:
      return Colors.blueGrey.shade300;
  }
}
