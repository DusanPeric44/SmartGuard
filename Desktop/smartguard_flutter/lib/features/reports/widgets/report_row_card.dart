import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';
import 'package:smartguard_flutter/features/reports/widgets/reports_format.dart';

class ReportRowCard extends StatelessWidget {
  const ReportRowCard({
    super.key,
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
                    '${row.reportType.name} ${fmtDateTime(row.generatedAtUtc ?? DateTime.now()) ?? ''}',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generated: ${fmtDateTime(row.generatedAtUtc) ?? '-'}',
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
