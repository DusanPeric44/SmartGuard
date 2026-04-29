import 'session_tokens.dart';

abstract interface class TokenStorage {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}
