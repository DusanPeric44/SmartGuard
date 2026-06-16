import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/dashboard_controller.dart';
import '../application/dashboard_state.dart';
import 'widgets/dashboard_alarms_row.dart';
import 'widgets/dashboard_quick_access_card.dart';
import 'widgets/dashboard_top_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    if (state.status == DashboardStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.refresh();
      });
    }

    return SafeArea(
      child: ListView(
        padding: AppDimens.pagePadding,
        children: [
          if (state.status == DashboardStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.status == DashboardStatus.error)
            AppErrorState(
              title: AppStrings.dashboardTitle,
              message: state.message ?? AppStrings.errorUnknown,
              onRetry: controller.refresh,
            )
          else ...[
            DashboardTopRow(devicesCount: state.devicesCount),
            DashboardAlarmsRow(
              pendingAlarmsCount: state.pendingAlarmsCount,
              onTap: () => context.go(AppRoutes.alarms),
            ),
            const SizedBox(height: AppDimens.spaceL),
            Text(
              AppStrings.dashboardQuickAccessTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.spaceM),
            if (state.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceM),
                child: Text(
                  AppStrings.dashboardQuickAccessEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.devices.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppDimens.spaceM),
                  itemBuilder: (context, index) {
                    final item = state.devices[index];
                    return DashboardQuickAccessCard(
                      title: item.name,
                      onTap: () =>
                          context.push(AppRoutes.deviceDetailPath(item.id)),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
