import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = false;
  String? _errorMessage;
  DashboardMetrics? _metrics;

  Future<void> _loadMetrics() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final api = AppScope.of(context).api;
    try {
      final responses = await Future.wait<Object?>([
        api.get<Object?>('/dashboard/summary'),
        api.get<Object?>('/alarms/active'),
      ]);

      if (!mounted) return;
      setState(() {
        _metrics = DashboardMetrics(
          systemSummary: responses[0],
          activeAlarms: responses[1],
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = UiErrorMapper.toMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Skeleton',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ovaj ekran demonstrira paralelno učitavanje nezavisnih API poziva preko Future.wait().',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _loading ? null : _loadMetrics,
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('Učitaj primjer'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _loading
                          ? null
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'TODO: proširiti dashboard kartice prema RS2 planu.',
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Roadmap TODO'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const AsyncStatePanel.loading()
        else if (_errorMessage != null)
          AsyncStatePanel.error(
            errorMessage: _errorMessage!,
            onRetry: _loadMetrics,
          )
        else if (_metrics != null)
          AsyncStatePanel.content(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(
                  title: 'System Summary',
                  value: _formatValue(_metrics!.systemSummary),
                ),
                _MetricCard(
                  title: 'Active Alarms',
                  value: _formatValue(_metrics!.activeAlarms),
                ),
              ],
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Kliknite "Učitaj primjer" da vidite reusable data-fetch obrazac za ovaj skeleton.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }

  String _formatValue(Object? value) {
    if (value == null) return 'N/A';
    return value.toString();
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.systemSummary,
    required this.activeAlarms,
  });

  final Object? systemSummary;
  final Object? activeAlarms;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
