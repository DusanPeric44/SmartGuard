import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';

class DashboardActiveDevicesCard extends StatelessWidget {
  const DashboardActiveDevicesCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceM,
          vertical: AppDimens.spaceS,
        ),
        leading: Icon(Icons.videocam_outlined, color: scheme.primary),
        title: Text(
          AppStrings.dashboardActiveTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        subtitle: Text(
          '$count',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
