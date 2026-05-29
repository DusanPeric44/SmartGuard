import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../constants/app_dimens.dart';
import '../constants/app_strings.dart';
import '../../features/notifications/application/notifications_controller.dart';
import '../../features/notifications/application/notifications_state.dart';
import '../../features/notifications/presentation/notification_dropdown_item.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/application/profile_state.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.location,
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final profile = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);
    final notifications = ref.watch(notificationsControllerProvider);
    final notificationsController = ref.read(
      notificationsControllerProvider.notifier,
    );

    if (profile.status == ProfileStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileController.load();
      });
    }

    if (notifications.status == NotificationsStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notificationsController.refreshDropdown();
      });
    }

    String initialFrom(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return '?';
      return trimmed.substring(0, 1).toUpperCase();
    }

    final initial = profile.fullName.trim().isNotEmpty
        ? initialFrom(profile.fullName)
        : initialFrom(profile.email);

    MenuController? menuController;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForLocation(location, currentIndex)),
        actions: [
          MenuAnchor(
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surface,
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
            ),
            builder: (context, controller, child) {
              menuController = controller;
              return Badge(
                isLabelVisible: notifications.unreadCount > 0,
                label: Text('${notifications.unreadCount}'),
                child: IconButton(
                  tooltip: AppStrings.notificationsTitle,
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () async {
                    if (controller.isOpen) {
                      controller.close();
                      return;
                    }
                    await notificationsController.refreshDropdown();
                    controller.open();
                  },
                ),
              );
            },
            menuChildren: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.notificationsTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (notifications.unreadCount > 0)
                        Text(
                          '${notifications.unreadCount} unread',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              if (notifications.status == NotificationsStatus.loading &&
                  notifications.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppDimens.spaceM),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (notifications.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppDimens.spaceM),
                  child: SizedBox(
                    width: 320,
                    child: Text(AppStrings.notificationsEmpty),
                  ),
                )
              else
                for (final item in notifications.items.take(8))
                  MenuItemButton(
                    onPressed: () async {
                      menuController?.close();
                      await notificationsController.markRead(item);
                    },
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    child: SizedBox(
                      width: 320,
                      child: NotificationDropdownItem(item: item),
                    ),
                  ),
              const Divider(height: 1),
              MenuItemButton(
                onPressed: notifications.unreadCount == 0
                    ? null
                    : () async {
                        menuController?.close();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text(
                                AppStrings.notificationsReadAll,
                              ),
                              content: const Text(
                                AppStrings.notificationsReadAllConfirmMessage,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(AppStrings.actionCancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    AppStrings.notificationsReadAll,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          await notificationsController.readAll();
                        }
                      },
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                child: SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          size: 18,
                          color: notifications.unreadCount == 0
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.35)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.notificationsReadAll,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: notifications.unreadCount == 0
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.35)
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.spaceM),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimens.pillRadius),
              onTap: () => context.push(AppRoutes.profile),
              child: CircleAvatar(
                radius: AppDimens.spaceM,
                child: Text(initial),
              ),
            ),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: AppStrings.navLive,
          ),
          NavigationDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: AppStrings.navArchive,
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: AppStrings.navAlarms,
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: AppStrings.navPersons,
          ),
        ],
      ),
    );
  }

  String _titleForLocation(String location, int index) {
    if (location.startsWith(AppRoutes.live)) return AppStrings.liveStreamTitle;
    if (location.startsWith(AppRoutes.archive)) {
      return AppStrings.recordingArchiveTitle;
    }
    if (location.startsWith(AppRoutes.alarms)) return AppStrings.alertsTitle;
    if (location.startsWith(AppRoutes.persons)) {
      return AppStrings.knownPersonsTitle;
    }
    if (location.startsWith(AppRoutes.profile)) return AppStrings.profileTitle;
    if (location.startsWith(AppRoutes.dashboard)) return AppStrings.navHome;

    return switch (index) {
      0 => AppStrings.navHome,
      1 => AppStrings.navLive,
      2 => AppStrings.navArchive,
      3 => AppStrings.navAlarms,
      4 => AppStrings.navPersons,
      _ => AppStrings.appTitle,
    };
  }
}
