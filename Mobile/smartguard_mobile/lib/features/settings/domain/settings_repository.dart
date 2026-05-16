import '../../../core/push/push_preferences.dart';

abstract interface class SettingsRepository {
  Future<bool> loadPushNotificationsEnabled();
  Future<void> setPushNotificationsEnabled(bool enabled);
}

class SecureSettingsRepository implements SettingsRepository {
  SecureSettingsRepository({PushPreferences? preferences})
    : _preferences = preferences ?? PushPreferences();

  final PushPreferences _preferences;

  @override
  Future<bool> loadPushNotificationsEnabled() async {
    return _preferences.loadEnabled();
  }

  @override
  Future<void> setPushNotificationsEnabled(bool enabled) {
    return _preferences.setEnabled(enabled);
  }
}
