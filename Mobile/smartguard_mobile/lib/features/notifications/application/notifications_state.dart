import '../domain/notification_item.dart';

enum NotificationsStatus { idle, loading, ready, error }

class NotificationsState {
  const NotificationsState._({
    required this.status,
    required this.unreadCount,
    required this.items,
    required this.message,
  });

  const NotificationsState.idle()
    : this._(
        status: NotificationsStatus.idle,
        unreadCount: 0,
        items: const [],
        message: null,
      );

  const NotificationsState.loading({
    required int unreadCount,
    required List<NotificationItem> items,
  })
    : this._(
        status: NotificationsStatus.loading,
        unreadCount: unreadCount,
        items: items,
        message: null,
      );

  const NotificationsState.ready({
    required int unreadCount,
    required List<NotificationItem> items,
  }) : this._(
         status: NotificationsStatus.ready,
         unreadCount: unreadCount,
         items: items,
         message: null,
       );

  const NotificationsState.error(
    String message, {
    required int unreadCount,
    required List<NotificationItem> items,
  })
    : this._(
        status: NotificationsStatus.error,
        unreadCount: unreadCount,
        items: items,
        message: message,
      );

  final NotificationsStatus status;
  final int unreadCount;
  final List<NotificationItem> items;
  final String? message;
}
