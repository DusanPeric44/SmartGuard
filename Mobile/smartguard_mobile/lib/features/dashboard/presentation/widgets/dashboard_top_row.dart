import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import 'dashboard_active_devices_card.dart';
import 'dashboard_system_status_card.dart';

class DashboardTopRow extends StatelessWidget {
  const DashboardTopRow({super.key, required this.devicesCount});

  final int devicesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(child: DashboardSystemStatusCard()),
        const SizedBox(width: AppDimens.spaceM),
        DashboardActiveDevicesCard(count: devicesCount),
      ],
    );
  }
}
