import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStore tokenStore})
    : _api = api,
      _tokenStore = tokenStore;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (AppConfig.enableStubAuth) {
      await _tokenStore.setToken('stub-token:${username.trim()}');
      await _tokenStore.setRefreshToken('stub-refresh-token:${username.trim()}');
      await _tokenStore.setRole(_roleForStubUsername(username));
      return;
    }

    final json = await _api.post<Object?>(
      '/auth/login',
      body: {'email': username, 'password': password},
    );

    final token = _extractToken(json);
    if (token == null || token.isEmpty) {
      throw StateError('Login odgovor ne sadrži token.');
    }

    final refreshToken = _extractRefreshToken(json);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Login odgovor ne sadrži refreshToken.');
    }

    await Future.wait([
      _tokenStore.setToken(token),
      _tokenStore.setRefreshToken(refreshToken),
      _tokenStore.setRole(_extractRole(json) ?? UserRole.viewer),
    ]);
  }

  Future<String?> fetchRegistrationKey() async {
    if (AppConfig.enableStubAuth) {
      return 'stub-registration-key-123';
    }

    try {
      final json = await _api.get<Object?>('/auth/registration-key');
      if (json is Map && json.containsKey('registrationKey')) {
        return json['registrationKey'] as String?;
      }
      if (json is String) return json;
      return null;
    } catch (_) {
      return null;
    }
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

  String? _extractRefreshToken(Object? json) {
    if (json is Map) {
      final candidates = <Object?>[
        json['refreshToken'],
        json['refresh_token'],
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c.trim();
      }
    }
    return null;
  }

  UserRole? _extractRole(Object? json) {
    if (json is Map) {
      final direct = json['role'];
      if (direct is String) return parseUserRole(direct);
      final user = json['user'];
      if (user is Map) {
        final nested = user['role'];
        if (nested is String) return parseUserRole(nested);
      }
    }
    return null;
  }

  UserRole _roleForStubUsername(String username) {
    final u = username.trim().toLowerCase();
    if (u.startsWith('admin')) return UserRole.admin;
    if (u.startsWith('home')) return UserRole.homeowner;
    return UserRole.viewer;
  }
}
