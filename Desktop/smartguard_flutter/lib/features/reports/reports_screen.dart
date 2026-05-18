import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/reports/data/api_reports_repository.dart';
import 'package:smartguard_flutter/features/reports/data/reports_repository.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';
import 'package:smartguard_flutter/features/reports/viewmodel/reports_view_model.dart';
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
        _FiltersCard(
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
          _Pager(
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
        return _ReportRowCard(
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

  Future<void> _openGenerate(ReportsViewModel vm) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GenerateReportDialog(vm: vm),
    );
    if (!mounted) return;
    if (res == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generation requested.')),
      );
    }
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onApply,
    required this.onReset,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback? onApply;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: onPickStart,
              icon: const Icon(Icons.date_range),
              label: Text(_fmt(start) ?? 'Start date'),
            ),
            FilledButton.tonalIcon(
              onPressed: onPickEnd,
              icon: const Icon(Icons.date_range),
              label: Text(_fmt(end) ?? 'End date'),
            ),
            FilledButton.tonalIcon(
              onPressed: onApply,
              icon: const Icon(Icons.filter_list),
              label: const Text('Filter'),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({
    required this.row,
    required this.isBusy,
    required this.onDownload,
  });

  final ReportRow row;
  final bool isBusy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row.reportType.name} ${_fmtDateTime(row.generatedAtUtc ?? DateTime.now()) ?? ''}',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generated: ${_fmtDateTime(row.generatedAtUtc) ?? '-'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isBusy ? null : onDownload,
              icon: isBusy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateReportDialog extends StatefulWidget {
  const _GenerateReportDialog({required this.vm});

  final ReportsViewModel vm;

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final busy = widget.vm.isGenerating;
        return AlertDialog(
          title: const Text('Generate report'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () async {
                                final picked = await _pickDate(_start);
                                if (picked == null) return;
                                setState(() => _start = picked);
                              },
                        icon: const Icon(Icons.date_range),
                        label: Text(_fmt(_start) ?? 'Start date'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () async {
                                final picked = await _pickDate(_end);
                                if (picked == null) return;
                                setState(() => _end = picked);
                              },
                        icon: const Icon(Icons.date_range),
                        label: Text(_fmt(_end) ?? 'End date'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final start = _start;
                      final end = _end;
                      if (start == null || end == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Start and end date are required.'),
                          ),
                        );
                        return;
                      }
                      if (end.isBefore(start)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End date must be after start date.'),
                          ),
                        );
                        return;
                      }
                      final ok = await widget.vm.generate(
                        start: start,
                        end: end,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop(ok);
                    },
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate'),
            ),
          ],
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
}

String? _fmt(DateTime? dt) {
  if (dt == null) return null;
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$d.$m.$y';
}

String? _fmtDateTime(DateTime? dt) {
  if (dt == null) return null;
  final date = _fmt(dt);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$date $h:$m';
}

String _suggestedFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'report.pdf';
  return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text('Total: $total'),
            const Spacer(),
            DropdownButton<int>(
              value: pageSize,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: isLoading ? null : (v) => onPageSizeChanged(v ?? 10),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: isLoading ? null : onPrev,
              child: const Text('Prev'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isLoading ? null : onNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
