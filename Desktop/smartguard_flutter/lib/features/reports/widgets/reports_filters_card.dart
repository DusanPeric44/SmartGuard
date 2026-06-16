import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/reports/widgets/reports_format.dart';

class ReportsFiltersCard extends StatelessWidget {
  const ReportsFiltersCard({
    super.key,
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
              label: Text(fmtDate(start) ?? 'Start date'),
            ),
            FilledButton.tonalIcon(
              onPressed: onPickEnd,
              icon: const Icon(Icons.date_range),
              label: Text(fmtDate(end) ?? 'End date'),
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
