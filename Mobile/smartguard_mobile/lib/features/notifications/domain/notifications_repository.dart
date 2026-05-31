import 'notification_item.dart';

abstract interface class NotificationsRepository {
  Future<int> getUnreadCount();
  Future<List<NotificationItem>> getLatest({int pageSize = 10});
  Future<void> markAsRead(int id);
  Future<int> markAllAsRead();
}
