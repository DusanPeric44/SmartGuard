import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.location,
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForLocation(location, currentIndex)),
        actions: [
          IconButton(
            onPressed: () {
              navigationShell.goBranch(2, initialLocation: true);
            },
            icon: const Icon(Icons.notifications),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alarm',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifikacije',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _titleForLocation(String location, int index) {
    if (location.startsWith('/dashboard/live-stream')) {
      return 'Live Stream';
    }
    if (location.startsWith('/dashboard/recordings')) {
      return 'Recording Archive';
    }
    if (location.startsWith('/dashboard/known-persons')) {
      return 'Known Persons';
    }
    if (location.startsWith('/dashboard/settings')) {
      return 'Settings';
    }

    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Alarm Center';
      case 2:
        return 'Notifikacije';
      case 3:
        return 'User Profile';
      default:
        return 'SmartGuard';
    }
  }
}
