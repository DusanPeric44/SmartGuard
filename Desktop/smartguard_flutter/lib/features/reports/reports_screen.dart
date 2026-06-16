import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/reports/data/api_reports_repository.dart';
import 'package:smartguard_flutter/features/reports/data/reports_repository.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';
import 'package:smartguard_flutter/features/reports/viewmodel/reports_view_model.dart';
import 'package:smartguard_flutter/features/reports/widgets/generate_report_dialog.dart';
import 'package:smartguard_flutter/features/reports/widgets/report_row_card.dart';
import 'package:smartguard_flutter/features/reports/widgets/reports_filters_card.dart';
import 'package:smartguard_flutter/features/reports/widgets/reports_pager.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportsRepository? _repo;
  ReportsViewModel? _vm;

  DateTime? _start;
  DateTime? _end;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiReportsRepository(api: AppScope.of(context).api);
    _vm = ReportsViewModel(repository: _repo!);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
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
    final page = vm.page;

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
                      Text('PDF Reports', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Generate and download system reports',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: vm.isGenerating ? null : () => _openGenerate(vm),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate Report'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ReportsFiltersCard(
          start: _start,
          end: _end,
          onPickStart: () async {
            final picked = await _pickDate(_start);
            if (picked == null) return;
            _start = picked;
            setState(() {});
          },
          onPickEnd: () async {
            final picked = await _pickDate(_end);
            if (picked == null) return;
            _end = picked;
            setState(() {});
          },
          onApply: vm.isLoading
              ? null
              : () async {
                  await vm.applyDateRange(_start, _end);
                },
          onReset: vm.isLoading
              ? null
              : () async {
                  _start = null;
                  _end = null;
                  setState(() {});
                  await vm.resetFilters();
                },
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm)),
        if (page != null) ...[
          const SizedBox(height: 12),
          ReportsPager(
            total: page.count,
            page: vm.pageNum,
            pageSize: vm.pageSize,
            isLoading: vm.isLoading,
            onPrev: vm.pageNum > 1 ? () => vm.changePage(vm.pageNum - 1) : null,
            onNext: (vm.pageNum * vm.pageSize) < page.count
                ? () => vm.changePage(vm.pageNum + 1)
                : null,
            onPageSizeChanged: (size) => vm.changePageSize(size),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(ReportsViewModel vm) {
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
                'No reports.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: page.result.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = page.result[index];
        final busy = vm.rowBusy[r.fileUrl] == true;
        return ReportRowCard(
          row: r,
          isBusy: busy,
          onDownload: () => _download(vm, r),
        );
      },
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: initial ?? now,
    );
  }

  Future<void> _download(ReportsViewModel vm, ReportRow row) async {
    if (row.fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report has no download path.')),
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
              Expanded(child: Text('Downloading report...')),
            ],
          ),
        ),
      ),
    );

    Uint8List? bytes;
    try {
      bytes = await vm.download(row);
    } finally {
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Download failed.')),
      );
      return;
    }

    final filePath = await _saveAs(
      _suggestedFileName(
        row.reportStatus.name + (row.generatedAtUtc?.toString() ?? ''),
      ),
      bytes,
    );
    if (!mounted) return;
    if (filePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download canceled.')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved: $filePath')));
  }

  Future<String?> _saveAs(String fileName, Uint8List bytes) async {
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return null;
    if (location.path.trim().isEmpty) return null;
    final file = File(location.path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _suggestedFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'report.pdf';
    return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
  }

  Future<void> _openGenerate(ReportsViewModel vm) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GenerateReportDialog(vm: vm),
    );
    if (!mounted) return;
    if (res == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generation requested.')),
      );
    }
  }
}
