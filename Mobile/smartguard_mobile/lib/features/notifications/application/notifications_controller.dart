import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/auth/session_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/realtime/signalr_client.dart';
import '../../../core/realtime/signalr_constants.dart';
import '../domain/api_notifications_repository.dart';
import '../domain/notification_item.dart';
import '../domain/notifications_repository.dart';
import 'notifications_state.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return ApiNotificationsRepository(ref.read(notificationsDioProvider));
});

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<NotificationsState> {
  SignalRClient? _client;
  bool _wired = false;

  @override
  NotificationsState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      final prevTokens = previous?.tokens;
      final nextTokens = next.tokens;

      final prevAccess = prevTokens?.accessToken;
      final nextAccess = nextTokens?.accessToken;

      final authChanged = prevAccess != nextAccess;
      final loggedOut =
          previous?.status == SessionStatus.authenticated &&
          next.status != SessionStatus.authenticated;

      if (loggedOut) {
        state = const NotificationsState.idle();
        _wired = false;
        final client = _client;
        _client = null;
        if (client != null) {
          client.dispose();
        }
        return;
      }

      if (next.status == SessionStatus.authenticated &&
          nextAccess != null &&
          nextAccess.trim().isNotEmpty &&
          (authChanged || _client == null)) {
        _startRealtime();
      }
    }, fireImmediately: true);

    ref.onDispose(() {
      final client = _client;
      _client = null;
      if (client != null) {
        client.dispose();
      }
    });

    return const NotificationsState.idle();
  }

  Future<void> _startRealtime() async {
    final existing = _client;
    if (existing != null) {
      await existing.dispose();
      _wired = false;
    }

    final session = ref.read(sessionControllerProvider.notifier);
    final client = SignalRClient.build(
      hubPath: SignalRConstants.notificationsHubPath,
      baseUrl: AppConfig.notificationsBaseUrl,
      accessTokenProvider: () async => session.tokens?.accessToken,
    );
    _client = client;

    if (!_wired) {
      _wired = true;

      client.on('NotificationCountChanged', (args) {
        final unread = _parseUnreadCount(args);
        if (unread == null) return;
        state = _copyWithUnreadCount(unread);
      });

      client.on('NewNotification', (args) {
        final parsed = _parseNotification(args);
        if (parsed == null) return;
        state = _prependIfMissing(parsed);
      });
    }

    try {
      await client.start();
    } catch (_) {}
  }

  NotificationsState _copyWithUnreadCount(int unreadCount) {
    return switch (state.status) {
      NotificationsStatus.idle => NotificationsState.ready(
        unreadCount: unreadCount,
        items: state.items,
      ),
      NotificationsStatus.loading => NotificationsState.loading(
        unreadCount: unreadCount,
        items: state.items,
      ),
      NotificationsStatus.ready => NotificationsState.ready(
        unreadCount: unreadCount,
        items: state.items,
      ),
      NotificationsStatus.error => NotificationsState.error(
        state.message ?? '',
        unreadCount: unreadCount,
        items: state.items,
      ),
    };
  }

  NotificationsState _prependIfMissing(NotificationItem item) {
    final existing = state.items;
    if (existing.any((x) => x.id == item.id)) return state;
    final next = [item, ...existing].take(20).toList(growable: false);

    return switch (state.status) {
      NotificationsStatus.idle => NotificationsState.ready(
        unreadCount: state.unreadCount,
        items: next,
      ),
      NotificationsStatus.loading => NotificationsState.loading(
        unreadCount: state.unreadCount,
        items: next,
      ),
      NotificationsStatus.ready => NotificationsState.ready(
        unreadCount: state.unreadCount,
        items: next,
      ),
      NotificationsStatus.error => NotificationsState.error(
        state.message ?? '',
        unreadCount: state.unreadCount,
        items: next,
      ),
    };
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

  Future<void> refreshDropdown() async {
    state = NotificationsState.loading(
      unreadCount: state.unreadCount,
      items: state.items,
    );
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final unreadCount = await repo.getUnreadCount();
      final items = await repo.getLatest(pageSize: 10);
      state = NotificationsState.ready(unreadCount: unreadCount, items: items);
    } catch (_) {
      state = const NotificationsState.error(
        'Neuspješno učitavanje notifikacija',
        unreadCount: 0,
        items: [],
      );
    }
  }

  Future<void> refresh() => refreshDropdown();

  Future<void> markRead(NotificationItem item) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
    } catch (_) {}
    await refreshDropdown();
  }

  Future<void> readAll() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
    } catch (_) {}
    await refreshDropdown();
  }
}
