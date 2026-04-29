import 'session_tokens.dart';

abstract interface class SessionManager {
  SessionTokens? get tokens;
  Future<SessionTokens?> refreshTokensSingleFlight();
  Future<void> setTokens(SessionTokens tokens);
  Future<void> logout();
}
