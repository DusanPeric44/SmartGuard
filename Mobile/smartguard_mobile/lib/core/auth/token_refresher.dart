import 'session_tokens.dart';

abstract interface class TokenRefresher {
  Future<SessionTokens?> refresh({required String refreshToken});
}

class StubTokenRefresher implements TokenRefresher {
  const StubTokenRefresher();

  @override
  Future<SessionTokens?> refresh({required String refreshToken}) async {
    return null;
  }
}
