import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_activity_row.dart';

class DashboardRecentActivityCard extends StatelessWidget {
  const DashboardRecentActivityCard({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = overview.lastAuditLogs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              const Text('No recent activity.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length.clamp(0, 12),
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final l = logs[index];
                  final title = [
                    l.action.trim(),
                    l.resource.trim(),
                  ].where((e) => e.isNotEmpty).join(' • ');
                  final subtitle = [
                    l.user.trim(),
                    l.details.trim(),
                  ].where((e) => e.isNotEmpty).join(' — ');
                  return DashboardActivityRow(
                    title: title.isEmpty ? 'Activity' : title,
                    subtitle: subtitle,
                    when: _timeAgo(l.timestamp),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
