import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../core/config/app_config.dart';
import 'auth_models.dart';
import 'oidc_auth_repository.dart';

class FlutterAppAuthOidcAuthRepository implements OidcAuthRepository {
  FlutterAppAuthOidcAuthRepository({FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  static const _clientId = 'flutter_app';
  static const _redirectUrl = 'com.smart.guard://callback';
  static const _scopes = <String>['openid', 'profile', 'smart-guard-api'];

  @override
  Future<AuthTokens?> signInWithGoogle() async {
    final issuer = AppConfig.apiBaseUrl;
    final uri = Uri.tryParse(issuer);
    final isHttp = uri != null && uri.scheme == 'http';

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          issuer: issuer,
          scopes: _scopes,
          allowInsecureConnections: isHttp,
        ),
      );
      final access = result.accessToken;
      final refresh = result.refreshToken;
      if (access == null || access.trim().isEmpty) {
        throw const FormatException('Missing access token');
      }
      if (refresh == null || refresh.trim().isEmpty) {
        throw const FormatException('Missing refresh token');
      }

      return AuthTokens(accessToken: access, refreshToken: refresh);
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }
}
