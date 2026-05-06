import 'package:flutter/material.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/data/stub_dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRepository _repo;
  late final DashboardViewModel _vm;

  @override
  void initState() {
    super.initState();
    _repo = _buildRepository();
    _vm = DashboardViewModel(repository: _repo);
    _vm.addListener(_onVmChanged);
    _vm.init();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  DashboardRepository _buildRepository() {
    if (AppConfig.enableStubData) {
      return StubDashboardRepository();
    }
    return StubDashboardRepository();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _DashboardHeader(
          lastRefresh: _vm.lastRefresh,
          isRefreshing: _vm.loadingAlerts || _vm.loadingKpis,
          autoRefresh: _vm.autoRefresh,
          interval: _vm.interval,
          onRefresh: () => _vm.refresh(),
          onAutoRefreshChanged: (v) => _vm.setAutoRefresh(v),
          onIntervalChanged: (d) => _vm.setInterval(d),
        ),
        const SizedBox(height: 16),
        _KpisSection(
          kpis: _vm.kpis,
          loading: _vm.loadingKpis,
          error: _vm.kpisError,
          onRetry: () => _vm.refresh(),
        ),
        const SizedBox(height: 16),
        _AlertsSection(
          alerts: _vm.alerts,
          loading: _vm.loadingAlerts,
          error: _vm.alertsError,
          onRetry: () => _vm.refresh(),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.lastRefresh,
    required this.isRefreshing,
    required this.autoRefresh,
    required this.interval,
    required this.onRefresh,
    required this.onAutoRefreshChanged,
    required this.onIntervalChanged,
  });

  final DateTime? lastRefresh;
  final bool isRefreshing;
  final bool autoRefresh;
  final Duration interval;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onAutoRefreshChanged;
  final ValueChanged<Duration> onIntervalChanged;

  @override
  Widget build(BuildContext context) {
    final last = lastRefresh == null ? '—' : _hhMm(lastRefresh!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'System Info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 12),
            Text('Last updated: $last'),
            const Spacer(),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<Duration>(
                initialValue: interval,
                items: const [
                  DropdownMenuItem(value: Duration(seconds: 15), child: Text('15s')),
                  DropdownMenuItem(value: Duration(seconds: 30), child: Text('30s')),
                  DropdownMenuItem(value: Duration(minutes: 1), child: Text('1m')),
                  DropdownMenuItem(value: Duration(minutes: 2), child: Text('2m')),
                ],
                onChanged: autoRefresh ? (v) => v == null ? null : onIntervalChanged(v) : null,
                decoration: const InputDecoration(labelText: 'Auto refresh'),
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: autoRefresh,
              onChanged: onAutoRefreshChanged,
            ),
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
  const _KpisSection({
    required this.kpis,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final DashboardKpis? kpis;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && kpis == null) {
      return const AsyncStatePanel.loading(message: 'Učitavam KPI...');
    }
    if (error != null && kpis == null) {
      return AsyncStatePanel.error(errorMessage: error!, onRetry: onRetry);
    }
    if (kpis == null) return const SizedBox.shrink();

    final k = kpis!;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _KpiCard(title: 'Devices Online', value: '${k.devicesOnline}', icon: Icons.wifi),
        _KpiCard(title: 'Devices Offline', value: '${k.devicesOffline}', icon: Icons.wifi_off),
        _KpiCard(title: 'Active Alarms', value: '${k.activeAlarms}', icon: Icons.warning_amber),
        _KpiCard(
          title: 'Recordings (24h)',
          value: '${k.recordingsLast24h}',
          icon: Icons.video_library_outlined,
        ),
        _StorageKpiCard(usedGb: k.storageUsedGb, totalGb: k.storageTotalGb),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({
    required this.alerts,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<DashboardAlert> alerts;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent alerts', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (loading && alerts.isEmpty)
              const AsyncStatePanel.loading(message: 'Učitavam alarme...')
            else if (error != null && alerts.isEmpty)
              AsyncStatePanel.error(errorMessage: error!, onRetry: onRetry)
            else if (alerts.isEmpty)
              const Text('Nema alarma.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Severity')),
                    DataColumn(label: Text('Title')),
                  ],
                  rows: [
                    for (final a in alerts)
                      DataRow(
                        cells: [
                          DataCell(Text(_hhMm(a.timestamp))),
                          DataCell(Text(a.severity)),
                          DataCell(Text(a.title)),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 6),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
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

class _StorageKpiCard extends StatelessWidget {
  const _StorageKpiCard({
    required this.usedGb,
    required this.totalGb,
  });

  final int usedGb;
  final int totalGb;

  @override
  Widget build(BuildContext context) {
    final pct = totalGb == 0 ? 0.0 : (usedGb / totalGb).clamp(0.0, 1.0);
    final warn = pct >= 0.85;
    return SizedBox(
      width: 540,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Storage'),
                  const Spacer(),
                  Text('$usedGb / $totalGb GB${warn ? ' (low)' : ''}'),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
                color: warn ? Colors.amberAccent.shade400 : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hhMm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
