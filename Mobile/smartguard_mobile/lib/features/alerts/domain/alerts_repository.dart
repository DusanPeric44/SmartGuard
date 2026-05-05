abstract interface class AlertsRepository {
  Future<List<String>> loadActiveAlertTitles();
}

class StubAlertsRepository implements AlertsRepository {
  const StubAlertsRepository();

  @override
  Future<List<String>> loadActiveAlertTitles() async {
    return const [];
  }
}
