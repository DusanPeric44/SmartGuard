import 'session_tokens.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState {
  const SessionState._({required this.status, required this.tokens});

  const SessionState.unknown()
    : this._(status: SessionStatus.unknown, tokens: null);

  const SessionState.unauthenticated()
    : this._(status: SessionStatus.unauthenticated, tokens: null);

  const SessionState.authenticated(SessionTokens tokens)
    : this._(status: SessionStatus.authenticated, tokens: tokens);

  final SessionStatus status;
  final SessionTokens? tokens;

  bool get isAuthenticated => status == SessionStatus.authenticated;
}
