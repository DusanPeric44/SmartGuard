import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

abstract class TokenStore {
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<UserRole?> getRole();
  Future<void> setRole(UserRole role);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  String? _token;
  UserRole? _role;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> setToken(String token) async {
    _token = token;
  }

  @override
  Future<UserRole?> getRole() async => _role;

  @override
  Future<void> setRole(UserRole role) async {
    _role = role;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _role = null;
  }
}

class SharedPrefsTokenStore implements TokenStore {
  SharedPrefsTokenStore._(this._prefs);

  static const _tokenKey = 'smartguard.auth.token';
  static const _roleKey = 'smartguard.auth.role';

  final SharedPreferences _prefs;

  static Future<SharedPrefsTokenStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsTokenStore._(prefs);
  }

  @override
  Future<String?> getToken() async => _prefs.getString(_tokenKey);

  @override
  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  @override
  Future<UserRole?> getRole() async {
    final raw = _prefs.getString(_roleKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return parseUserRole(raw);
  }

  @override
  Future<void> setRole(UserRole role) async {
    await _prefs.setString(_roleKey, userRoleToWire(role));
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_roleKey);
  }
}
