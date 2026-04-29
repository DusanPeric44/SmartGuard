import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStore {
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> setToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}

class SharedPrefsTokenStore implements TokenStore {
  SharedPrefsTokenStore._(this._prefs);

  static const _tokenKey = 'smartguard.auth.token';

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
  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
  }
}
