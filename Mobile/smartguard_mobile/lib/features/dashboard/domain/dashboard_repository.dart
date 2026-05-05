abstract interface class DashboardRepository {
  Future<int> loadUnreadNotificationsCount();
  Future<int> loadActiveCamerasCount();
  Future<int> loadNewAlarmsCount();
}

class StubDashboardRepository implements DashboardRepository {
  const StubDashboardRepository();

  @override
  Future<int> loadUnreadNotificationsCount() async {
    return 0;
  }

  @override
  Future<int> loadActiveCamerasCount() async {
    return 0;
  }

  @override
  Future<int> loadNewAlarmsCount() async {
    return 0;
  }
}
