import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../constants/app_dimens.dart';
import '../constants/app_strings.dart';
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

    if (profile.status == ProfileStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileController.load();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForLocation(location, currentIndex)),
        actions: [
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
