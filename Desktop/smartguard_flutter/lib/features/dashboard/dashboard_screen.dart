import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/dashboard/data/api_dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardRepository? _repo;
  DashboardViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = _buildRepository();
    _vm = DashboardViewModel(repository: _repo!);
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

  DashboardRepository _buildRepository() {
    return ApiDashboardRepository(api: AppScope.of(context).api);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Center(child: AsyncStatePanel.loading());

    final overview = vm.overview;
    return ListView(
      children: [
        _DashboardHeader(
          lastRefresh: vm.lastRefresh,
          isRefreshing: vm.isLoading,
          onRefresh: () => vm.refresh(),
        ),
        const SizedBox(height: 16),
        if (vm.isLoading && overview == null)
          const AsyncStatePanel.loading(message: 'Loading dashboard...')
        else if (vm.errorMessage != null && overview == null)
          AsyncStatePanel.error(
            errorMessage: vm.errorMessage!,
            onRetry: vm.refresh,
          )
        else if (overview == null)
          const SizedBox.shrink()
        else ...[
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vm.errorMessage!),
                ),
              ),
            ),
          _KpisSection(overview: overview),
          const SizedBox(height: 16),
          _BottomSection(overview: overview),
        ],
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.lastRefresh,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DateTime? lastRefresh;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final last = lastRefresh == null ? '—' : _hhMm(lastRefresh!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('System Info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 12),
            Text('Last updated: $last'),
            const Spacer(),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpisSection extends StatelessWidget {
  const _KpisSection({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final devicesOnline = overview.connectedDevicesCount;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _KpiCard(
          title: 'Devices',
          value: '${overview.devicesCount}',
          subtitle: '$devicesOnline Online',
          icon: Icons.videocam_outlined,
          accentColor: Colors.greenAccent.shade400,
        ),
        _KpiCard(
          title: 'Recordings',
          value: '${overview.recordingsCount}',
          subtitle: 'Total recordings',
          icon: Icons.video_library_outlined,
          accentColor: Theme.of(context).colorScheme.primary,
        ),
        _KpiCard(
          title: 'Alarms',
          value: '${overview.pendingAlarmsCount}',
          subtitle: 'Pending review',
          icon: Icons.warning_amber_rounded,
          accentColor: Colors.redAccent.shade200,
        ),
        _KpiCard(
          title: 'Users',
          value: '${overview.activeUsersCount}',
          subtitle: 'Active accounts',
          icon: Icons.people_alt_outlined,
          accentColor: Colors.tealAccent.shade400,
        ),
      ],
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final storage = _StorageCard(overview: overview);
        final activity = _RecentActivityCard(overview: overview);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: storage),
              const SizedBox(width: 16),
              Expanded(child: activity),
            ],
          );
        }

        return Column(
          children: [storage, const SizedBox(height: 16), activity],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.overview});

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
                _LegendDot(
                  color: Colors.redAccent.shade200,
                  label: 'Videos',
                  value: _bytesLabel(overview.usedVideosBytes),
                ),
                _LegendDot(
                  color: Colors.tealAccent.shade400,
                  label: 'Images',
                  value: _bytesLabel(overview.usedImagesBytes),
                ),
                _LegendDot(
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.overview});

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
                  return _ActivityRow(
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.when,
  });

  final String title;
  final String subtitle;
  final String when;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            when,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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

String _timeAgo(DateTime? dt) {
  if (dt == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _hhMm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
