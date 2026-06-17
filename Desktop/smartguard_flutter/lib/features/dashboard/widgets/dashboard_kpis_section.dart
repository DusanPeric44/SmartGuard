import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_kpi_card.dart';

class DashboardKpisSection extends StatelessWidget {
  const DashboardKpisSection({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final devicesOnline = overview.connectedDevicesCount;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        DashboardKpiCard(
          title: 'Devices',
          value: '${overview.devicesCount}',
          subtitle: '$devicesOnline Online',
          icon: Icons.videocam_outlined,
          accentColor: Colors.greenAccent.shade400,
        ),
        DashboardKpiCard(
          title: 'Recordings',
          value: '${overview.recordingsCount}',
          subtitle: 'Total recordings',
          icon: Icons.video_library_outlined,
          accentColor: Theme.of(context).colorScheme.primary,
        ),
        DashboardKpiCard(
          title: 'Alarms',
          value: '${overview.pendingAlarmsCount}',
          subtitle: 'Pending review',
          icon: Icons.warning_amber_rounded,
          accentColor: Colors.redAccent.shade200,
        ),
        DashboardKpiCard(
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
