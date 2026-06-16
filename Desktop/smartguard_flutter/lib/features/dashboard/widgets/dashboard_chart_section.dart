import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_legend_dot.dart';

class DashboardChartSection extends StatelessWidget {
  const DashboardChartSection({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videos = overview.usedVideosBytes.toDouble();
    final images = overview.usedImagesBytes.toDouble();
    final reports = overview.usedReportsBytes.toDouble();
    final total = videos + images + reports;

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: videos == 0 ? 1 : videos,
        title: '',
        color: Colors.redAccent.shade200,
        radius: 48,
      ),
      PieChartSectionData(
        value: images == 0 ? 1 : images,
        title: '',
        color: Colors.tealAccent.shade400,
        radius: 48,
      ),
      PieChartSectionData(
        value: reports == 0 ? 1 : reports,
        title: '',
        color: Colors.amberAccent.shade400,
        radius: 48,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage Information', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 70,
                      sectionsSpace: 1.5,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _bytesLabel(total.toInt()),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Used',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                DashboardLegendDot(
                  color: Colors.redAccent.shade200,
                  label: 'Videos',
                  value: _bytesLabel(overview.usedVideosBytes),
                ),
                DashboardLegendDot(
                  color: Colors.tealAccent.shade400,
                  label: 'Images',
                  value: _bytesLabel(overview.usedImagesBytes),
                ),
                DashboardLegendDot(
                  color: Colors.amberAccent.shade400,
                  label: 'Reports',
                  value: _bytesLabel(overview.usedReportsBytes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _bytesLabel(int bytes) {
  if (bytes < 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024.0;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024.0;
  if (gb < 1024) return '${gb.toStringAsFixed(2)} GB';
  final tb = gb / 1024.0;
  return '${tb.toStringAsFixed(2)} TB';
}
