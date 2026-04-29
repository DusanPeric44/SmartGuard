abstract interface class SettingsRepository {
  Future<bool> loadPushNotificationsEnabled();
  Future<void> setPushNotificationsEnabled(bool enabled);
}

class StubSettingsRepository implements SettingsRepository {
  const StubSettingsRepository();

  @override
  Future<bool> loadPushNotificationsEnabled() async {
    return false;
  }

  @override
  Future<void> setPushNotificationsEnabled(bool enabled) async {}
}
