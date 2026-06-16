import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';

class DashboardAlarmsRow extends StatelessWidget {
  const DashboardAlarmsRow({
    super.key,
    required this.pendingAlarmsCount,
    required this.onTap,
  });

  final int pendingAlarmsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasAlarms = pendingAlarmsCount > 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: InkWell(
        borderRadius: AppDimens.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spaceM),
          child: Row(
            children: [
              Icon(
                Icons.notification_important_outlined,
                color: hasAlarms ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dashboardNewAlarmsTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppDimens.spaceS),
                    Text(
                      '$pendingAlarmsCount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              if (hasAlarms)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceM,
                    vertical: AppDimens.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(AppDimens.pillRadius),
                  ),
                  child: Text(
                    AppStrings.dashboardActionRequired,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: scheme.onError),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
