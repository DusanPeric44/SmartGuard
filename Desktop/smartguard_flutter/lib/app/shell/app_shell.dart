import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/app/navigation/app_nav_items.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentUri,
  });

  final Widget child;
  final Uri currentUri;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _railExtended = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final role = AppScope.of(context).auth.role;
    final filteredNavItems = appNavItems.where((it) {
      if (it.id == 'devices' && role == UserRole.admin) return false;
      return true;
    }).toList(growable: false);

    final selectedIndex = _selectedNavIndex(widget.currentUri, filteredNavItems);
    final pageTitle = _titleForUri(widget.currentUri, filteredNavItems);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(pageTitle),
            ),
            if (isWide)
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search devices, users, recordings...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Diagnostics',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Diagnostics'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API base URL: ${AppScope.of(context).api.baseUri}'),
                    const SizedBox(height: 8),
                    Text('Stub auth: ${AppConfig.enableStubAuth ? 'uključen' : 'isključen'}'),
                    const SizedBox(height: 8),
                    Text('Role: ${userRoleToWire(AppScope.of(context).auth.role)}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zatvori'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
          Badge(
            label: const Text('8'),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Odjava',
            onPressed: () async {
              await AppScope.of(context).auth.logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Odjavljeni ste.')),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: _DrawerNav(
                  navItems: filteredNavItems,
                  selectedIndex: selectedIndex,
                  onNavigate: (route) {
                    Navigator.of(context).pop();
                    context.go(route);
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              extended: _railExtended,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(filteredNavItems[index].route),
              leading: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _railExtended = !_railExtended),
                      icon: Icon(_railExtended ? Icons.chevron_left : Icons.menu),
                      label: Text(_railExtended ? 'Collapse' : 'Menu'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              destinations: [
                for (final item in filteredNavItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  int _selectedNavIndex(Uri uri, List<AppNavItem> items) {
    final location = uri.path.isEmpty ? '/' : uri.path;
    final idx = items.indexWhere(
      (it) => location == it.route || location.startsWith('${it.route}/'),
    );
    return idx >= 0 ? idx : 0;
  }

  String _titleForUri(Uri uri, List<AppNavItem> items) {
    final location = uri.path.isEmpty ? '/' : uri.path;
    final match = items.where((it) => it.route == location).toList(growable: false);
    return match.isNotEmpty ? match.first.label : 'SmartGuard';
  }
}

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({
    required this.navItems,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final List<AppNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ListTile(
          title: Text(
            'SmartGuard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('IoT Security System'),
          leading: Icon(Icons.shield_outlined),
        ),
        const Divider(height: 1),
        for (var i = 0; i < navItems.length; i++)
          ListTile(
            leading: Icon(navItems[i].icon),
            title: Text(navItems[i].label),
            selected: i == selectedIndex,
            onTap: () => onNavigate(navItems[i].route),
          ),
      ],
    );
  }
}
