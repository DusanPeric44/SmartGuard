import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PushPreferences {
  PushPreferences({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _kEnabledKey = 'push_enabled';
  static const String _kPendingRouteKey = 'push_pending_route';

  final FlutterSecureStorage _storage;

  Future<bool> loadEnabled() async {
    final raw = await _storage.read(key: _kEnabledKey);
    if (raw == null) return true;
    return raw.trim().toLowerCase() == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _kEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<String?> loadPendingRoute() {
    return _storage.read(key: _kPendingRouteKey);
  }

  Future<void> setPendingRoute(String route) {
    return _storage.write(key: _kPendingRouteKey, value: route);
  }

  Future<void> clearPendingRoute() {
    return _storage.delete(key: _kPendingRouteKey);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _kEnabledKey);
    await _storage.delete(key: _kPendingRouteKey);
  }
}
