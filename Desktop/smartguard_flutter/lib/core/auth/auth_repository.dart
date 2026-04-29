import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient api,
    required TokenStore tokenStore,
  })  : _api = api,
        _tokenStore = tokenStore;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (AppConfig.enableStubAuth) {
      await _tokenStore.setToken('stub-token:${username.trim()}');
      return;
    }

    final json = await _api.post<Object?>(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
    );

    final token = _extractToken(json);
    if (token == null || token.isEmpty) {
      throw StateError('Login odgovor ne sadrži token.');
    }

    await _tokenStore.setToken(token);
  }

  Future<void> logout() async {
    await _tokenStore.clear();
  }

  Future<bool> hasToken() async {
    final token = await _tokenStore.getToken();
    return token != null && token.isNotEmpty;
  }

  String? _extractToken(Object? json) {
    if (json is Map) {
      final candidates = <Object?>[
        json['accessToken'],
        json['access_token'],
        json['token'],
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c.trim();
      }
    }
    return null;
  }
}
