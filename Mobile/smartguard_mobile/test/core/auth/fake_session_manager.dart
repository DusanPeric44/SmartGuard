import 'package:smart_guard_flutter/core/auth/session_manager.dart';
import 'package:smart_guard_flutter/core/auth/session_tokens.dart';

class FakeSessionManager implements SessionManager {
  FakeSessionManager({this.initialTokens, this.refreshResult});

  final SessionTokens? initialTokens;
  SessionTokens? refreshResult;

  int refreshCalls = 0;
  int logoutCalls = 0;
  SessionTokens? _tokens;

  @override
  SessionTokens? get tokens => _tokens ?? initialTokens;

  @override
  Future<SessionTokens?> refreshTokensSingleFlight() async {
    refreshCalls += 1;
    _tokens = refreshResult ?? _tokens ?? initialTokens;
    return refreshResult;
  }

  @override
  Future<void> setTokens(SessionTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    _tokens = null;
  }
}
