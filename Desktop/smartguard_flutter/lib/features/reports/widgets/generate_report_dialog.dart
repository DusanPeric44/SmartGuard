import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/reports/viewmodel/reports_view_model.dart';
import 'package:smartguard_flutter/features/reports/widgets/reports_format.dart';

class GenerateReportDialog extends StatefulWidget {
  const GenerateReportDialog({super.key, required this.vm});

  final ReportsViewModel vm;

  @override
  State<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  DateTime? _start;
  DateTime? _end;
  String? _error;

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
                        label: Text(fmtDate(_start) ?? 'Start date'),
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
                        label: Text(fmtDate(_end) ?? 'End date'),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
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
                        setState(
                          () => _error = 'Start and end date are required.',
                        );
                        return;
                      }
                      if (end.isBefore(start)) {
                        setState(
                          () =>
                              _error = 'End date must be after the start date.',
                        );
                        return;
                      }
                      setState(() => _error = null);
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
