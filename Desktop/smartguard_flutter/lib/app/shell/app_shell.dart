import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/app/navigation/app_nav_items.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/core/notifications/notification_item.dart';
import 'package:smartguard_flutter/core/notifications/notification_dropdown_item.dart';
import 'package:smartguard_flutter/core/notifications/notifications_api.dart';
import 'package:smartguard_flutter/core/realtime/signalr_client.dart';
import 'package:smartguard_flutter/core/realtime/signalr_constants.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.currentUri});

  final Widget child;
  final Uri currentUri;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _railExtended = true;
  final _searchController = TextEditingController();
  int _unreadCount = 0;
  bool _notificationsLoading = false;
  List<NotificationItem> _notifications = const [];
  bool _didLoadUnreadCount = false;
  SignalRClient? _notificationsHub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadUnreadCount) return;
    _didLoadUnreadCount = true;
    _refreshUnreadCount();
    _startNotificationsRealtime();
  }

  @override
  void dispose() {
    final hub = _notificationsHub;
    _notificationsHub = null;
    if (hub != null) {
      hub.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startNotificationsRealtime() async {
    if (_notificationsHub != null) return;

    final hub = SignalRClient.build(
      baseUri: AppConfig.notificationsBaseUri,
      hubPath: SignalRConstants.notificationsHubPath,
      accessTokenProvider: () => AppScope.of(context).auth.accessToken,
    );
    _notificationsHub = hub;

    hub.on('NotificationCountChanged', (args) {
      final count = _parseUnreadCount(args);
      if (count == null) return;
      if (!mounted) return;
      setState(() => _unreadCount = count);
    });

    hub.on('NewNotification', (args) {
      final item = _parseNotification(args);
      if (item == null) return;
      if (!mounted) return;
      setState(() {
        if (_notifications.any((x) => x.id == item.id)) return;
        _notifications = [
          item,
          ..._notifications,
        ].take(20).toList(growable: false);
      });
    });

    try {
      await hub.start();
    } catch (_) {}
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final api = NotificationsApi(api: AppScope.of(context).notificationsApi);
      final count = await api.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
  }

  int? _parseUnreadCount(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final first = args.first;
    if (first is Map) {
      final raw = first['unreadCount'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '');
    }
    return null;
  }

  NotificationItem? _parseNotification(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final first = args.first;
    if (first is Map) {
      return NotificationItem.fromJson(Map<String, dynamic>.from(first));
    }
    return null;
  }

  Future<void> _refreshNotificationsDropdown() async {
    if (_notificationsLoading) return;
    setState(() => _notificationsLoading = true);
    try {
      final api = NotificationsApi(api: AppScope.of(context).notificationsApi);
      final count = await api.getUnreadCount();
      final items = await api.getLatest(pageSize: 10);
      if (!mounted) return;
      setState(() {
        _unreadCount = count;
        _notifications = items;
        _notificationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _notificationsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final selectedIndex = _selectedNavIndex(widget.currentUri);
    final pageTitle = _titleForUri(widget.currentUri);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Expanded(child: Text(pageTitle))]),
        actions: [
          Builder(
            builder: (context) {
              MenuController? menuController;
              return MenuAnchor(
                style: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surface,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                    isLabelVisible: _unreadCount > 0,
                    label: Text('$_unreadCount'),
                    child: IconButton(
                      tooltip: 'Notifications',
                      onPressed: () async {
                        if (controller.isOpen) {
                          controller.close();
                          return;
                        }
                        await _refreshNotificationsDropdown();
                        controller.open();
                      },
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  );
                },
                menuChildren: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: SizedBox(
                      width: 360,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Notifications',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Text(
                              '$_unreadCount unread',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_notificationsLoading && _notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 360,
                        child: Text('No notifications'),
                      ),
                    )
                  else
                    for (final item in _notifications.take(10))
                      MenuItemButton(
                        onPressed: () async {
                          menuController?.close();
                          try {
                            final api = NotificationsApi(
                              api: AppScope.of(context).notificationsApi,
                            );
                            await api.markAsRead(item.id);
                          } catch (_) {}
                          await _refreshNotificationsDropdown();
                        },
                        style: const ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        ),
                        child: SizedBox(
                          width: 360,
                          child: NotificationDropdownItem(item: item),
                        ),
                      ),
                  const Divider(height: 1),
                  MenuItemButton(
                    onPressed: _unreadCount == 0
                        ? null
                        : () async {
                            menuController?.close();
                            final notificationsApi =
                                AppScope.of(context).notificationsApi;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Read all'),
                                  content: const Text(
                                    'Mark all notifications as read?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Read all'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmed == true) {
                              try {
                                final api = NotificationsApi(
                                  api: notificationsApi,
                                );
                                await api.markAllAsRead();
                              } catch (_) {}
                              await _refreshNotificationsDropdown();
                            }
                          },
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    child: SizedBox(
                      width: 360,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.done_all,
                              size: 18,
                              color: _unreadCount == 0
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.35)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Read all',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _unreadCount == 0
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.35)
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'Odjava',
            onPressed: () async {
              await AppScope.of(context).auth.logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Odjavljeni ste.')));
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
              onDestinationSelected: (index) =>
                  context.go(appNavItems[index].route),
              leading: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    _railExtended
                        ? FilledButton.tonalIcon(
                            onPressed: () =>
                                setState(() => _railExtended = !_railExtended),
                            icon: Icon(Icons.chevron_left),
                            label: const Text('Collapse'),
                          )
                        : IconButton(
                            onPressed: () =>
                                setState(() => _railExtended = !_railExtended),
                            icon: Icon(Icons.menu),
                          ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              destinations: [
                for (final item in appNavItems)
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

  int _selectedNavIndex(Uri uri) {
    final location = uri.path.isEmpty ? '/' : uri.path;
    final idx = appNavItems.indexWhere(
      (it) => location == it.route || location.startsWith('${it.route}/'),
    );
    return idx >= 0 ? idx : 0;
  }

  String _titleForUri(Uri uri) {
    final location = uri.path.isEmpty ? '/' : uri.path;
    final match = appNavItems
        .where((it) => it.route == location)
        .toList(growable: false);
    return match.isNotEmpty ? match.first.label : 'SmartGuard';
  }
}

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({required this.selectedIndex, required this.onNavigate});

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
        for (var i = 0; i < appNavItems.length; i++)
          ListTile(
            leading: Icon(appNavItems[i].icon),
            title: Text(appNavItems[i].label),
            selected: i == selectedIndex,
            onTap: () => onNavigate(appNavItems[i].route),
          ),
      ],
    );
  }
}
