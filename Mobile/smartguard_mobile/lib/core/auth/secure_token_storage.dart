import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_tokens.dart';
import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccessTokenKey = 'access_token';
  static const _kRefreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async {
    final accessToken = await _storage.read(key: _kAccessTokenKey);
    final refreshToken = await _storage.read(key: _kRefreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) return null;
    return SessionTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    await _storage.write(key: _kAccessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _kRefreshTokenKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
  }
}
