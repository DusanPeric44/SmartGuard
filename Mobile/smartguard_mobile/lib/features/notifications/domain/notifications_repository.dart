import 'notification_item.dart';

abstract interface class NotificationsRepository {
  Future<int> getUnreadCount();
  Future<List<NotificationItem>> getLatest({int pageSize = 10});
  Future<void> markAsRead(int id);
  Future<int> markAllAsRead();
}

class StubNotificationsRepository implements NotificationsRepository {
  const StubNotificationsRepository();

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<List<NotificationItem>> getLatest({int pageSize = 10}) async => const [];

  @override
  Future<void> markAsRead(int id) async {}

  @override
  Future<int> markAllAsRead() async => 0;
}
