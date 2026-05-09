import '../../../core/auth/session_tokens.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  SessionTokens toSessionTokens() {
    return SessionTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  static AuthTokens fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('AuthTokens: expected object');
    }

    final map = Map<String, dynamic>.from(json);

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    final access = pick(const ['accessToken', 'access_token', 'token', 'jwt']);
    final refresh = pick(const ['refreshToken', 'refresh_token']);

    if (access == null || refresh == null) {
      throw const FormatException('AuthTokens: missing token fields');
    }

    return AuthTokens(accessToken: access, refreshToken: refresh);
  }
}
