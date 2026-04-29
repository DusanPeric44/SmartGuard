abstract interface class AlarmCenterRepository {
  Future<int> loadActiveAlarmCount();
}

class StubAlarmCenterRepository implements AlarmCenterRepository {
  const StubAlarmCenterRepository();

  @override
  Future<int> loadActiveAlarmCount() async {
    return 0;
  }
}
