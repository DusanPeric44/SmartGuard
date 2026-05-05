abstract interface class NotificationsRepository {
  Future<List<String>> loadLatestNotificationTitles();
}

class StubNotificationsRepository implements NotificationsRepository {
  const StubNotificationsRepository();

  @override
  Future<List<String>> loadLatestNotificationTitles() async {
    return const [];
  }
}
