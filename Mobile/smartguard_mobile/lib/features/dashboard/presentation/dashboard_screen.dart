import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/dashboard_controller.dart';
import '../application/dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String _deviceIdQueryKey = 'deviceId';

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
            _TopRow(devicesCount: state.devicesCount),
            _AlarmsRow(
              pendingAlarmsCount: state.pendingAlarmsCount,
              onTap: () => context.go(AppRoutes.alarmCenter),
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
                    return _QuickAccessCard(
                      title: item.name,
                      onTap: () => context.go(
                        Uri(
                          path: AppRoutes.dashboardLiveStream,
                          queryParameters: <String, String>{
                            _deviceIdQueryKey: item.id.toString(),
                          },
                        ).toString(),
                      ),
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

class _TopRow extends StatelessWidget {
  const _TopRow({required this.devicesCount});

  final int devicesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(child: _SystemStatusCard()),
        const SizedBox(width: AppDimens.spaceM),
        _ActiveDevicesCard(count: devicesCount),
      ],
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard();

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

class _ActiveDevicesCard extends StatelessWidget {
  const _ActiveDevicesCard({required this.count});

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

class _AlarmsRow extends StatelessWidget {
  const _AlarmsRow({required this.pendingAlarmsCount, required this.onTap});

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

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.spaceM),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
