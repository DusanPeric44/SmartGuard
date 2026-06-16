import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/features/recordings/data/api_recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';
import 'package:smartguard_flutter/features/recordings/viewmodel/recordings_view_model.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_filters_card.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_format.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_pager.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_table.dart';
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
        RecordingsFiltersCard(
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
              child: RecordingsTable(
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
        RecordingsPager(
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

    final vm = _vm;
    if (vm == null) return;
    final row = (vm.page?.items ?? const []).where((r) => r.id == id).firstOrNull;
    final label = row == null
        ? 'snimak'
        : 'snimak (${row.deviceName.trim().isEmpty ? 'uređaj' : row.deviceName} '
              '· ${recordingDate(row.startedAt)} ${recordingTime(row.startedAt)})';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft delete'),
        content: Text('Obrisati $label? Snimak će biti označen kao obrisan.'),
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

    await vm.softDelete(id);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Snimak je obrisan.')));
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
