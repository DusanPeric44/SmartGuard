import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../application/dashboard_controller.dart';
import '../application/dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dashboard (placeholder)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _StatusLine(state: state),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.status == DashboardStatus.loading
                ? null
                : () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
            child: const Text('Refresh summary'),
          ),
          const SizedBox(height: 16),
          Text('Unread notifications: ${state.unreadNotifications}'),
          const SizedBox(height: 8),
          Text('Active cameras: ${state.activeCameras}'),
          const SizedBox(height: 8),
          Text('New alarms: ${state.newAlarms}'),
          const SizedBox(height: 16),
          _NavTile(
            title: 'Live Stream',
            onTap: () => context.go(AppRoutes.dashboardLiveStream),
          ),
          _NavTile(
            title: 'Recording Archive',
            onTap: () => context.go(AppRoutes.dashboardRecordings),
          ),
          _NavTile(
            title: 'Known Persons',
            onTap: () => context.go(AppRoutes.dashboardKnownPersons),
          ),
          _NavTile(
            title: 'Settings',
            onTap: () => context.go(AppRoutes.dashboardSettings),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      DashboardStatus.idle => 'Idle',
      DashboardStatus.loading => 'Loading',
      DashboardStatus.ready => 'Ready',
      DashboardStatus.error => 'Error',
    };

    return Row(
      children: [
        Text('Status: $label'),
        if (state.message != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
