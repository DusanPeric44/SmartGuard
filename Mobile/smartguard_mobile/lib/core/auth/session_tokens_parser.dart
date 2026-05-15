import 'session_tokens.dart';

class SessionTokensParser {
  const SessionTokensParser();

  SessionTokens fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('SessionTokens: expected object');
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
      throw const FormatException('SessionTokens: missing token fields');
    }

    return SessionTokens(accessToken: access, refreshToken: refresh);
  }
}

