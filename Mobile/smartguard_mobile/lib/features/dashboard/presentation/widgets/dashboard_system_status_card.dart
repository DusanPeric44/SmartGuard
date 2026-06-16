import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';

class DashboardSystemStatusCard extends StatelessWidget {
  const DashboardSystemStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        decoration: BoxDecoration(color: scheme.tertiaryContainer),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: scheme.onTertiaryContainer),
            const SizedBox(width: AppDimens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.dashboardSystemStatusTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceS),
                  Text(
                    AppStrings.dashboardSystemStatusArmed,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
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
