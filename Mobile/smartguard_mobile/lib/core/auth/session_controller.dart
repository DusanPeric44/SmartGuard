import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_token_storage.dart';
import 'session_manager.dart';
import 'session_state.dart';
import 'session_tokens.dart';
import 'token_refresher.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final tokenRefresherProvider = Provider<TokenRefresher>((ref) {
  return const StubTokenRefresher();
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState>
    implements SessionManager {
  Future<SessionTokens?>? _refreshInFlight;
  bool _didRestore = false;

  @override
  SessionState build() {
    if (!_didRestore) {
      _didRestore = true;
      unawaited(_restoreFromStorage());
    }
    return const SessionState.unknown();
  }

  @override
  SessionTokens? get tokens => state.tokens;

  Future<void> _restoreFromStorage() async {
    final stored = await ref.read(tokenStorageProvider).read();
    if (stored == null) {
      state = const SessionState.unauthenticated();
      return;
    }
    state = SessionState.authenticated(stored);
  }

  @override
  Future<void> setTokens(SessionTokens tokens) async {
    await ref.read(tokenStorageProvider).write(tokens);
    state = SessionState.authenticated(tokens);
  }

  @override
  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const SessionState.unauthenticated();
  }

  @override
  Future<SessionTokens?> refreshTokensSingleFlight() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final refreshToken = state.tokens?.refreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return Future.value(null);
    }

    final completer = Completer<SessionTokens?>();
    _refreshInFlight = completer.future;

    () async {
      try {
        final refreshed = await ref
            .read(tokenRefresherProvider)
            .refresh(refreshToken: refreshToken);
        if (refreshed != null) {
          await setTokens(refreshed);
        }
        completer.complete(refreshed);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _refreshInFlight = null;
      }
    }();

    return completer.future;
  }
}
