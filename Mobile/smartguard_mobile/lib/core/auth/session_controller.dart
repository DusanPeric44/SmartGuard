import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
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
  return ApiTokenRefresher(ref.read(authDioProvider));
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState>
    implements SessionManager {
  Future<SessionTokens?>? _refreshInFlight;
  Future<void>? _restoreInFlight;
  bool _didRestore = false;

  @override
  SessionState build() {
    if (!_didRestore) {
      _didRestore = true;
      _restoreInFlight ??= _restoreFromStorage();
      unawaited(_restoreInFlight!);
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

  Future<void> _ensureRestored() async {
    if (state.status != SessionStatus.unknown) return;
    final existing = _restoreInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    _restoreInFlight = _restoreFromStorage();
    await _restoreInFlight;
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

    final completer = Completer<SessionTokens?>();
    _refreshInFlight = completer.future;

    () async {
      try {
        await _ensureRestored();

        final token = state.tokens?.accessToken;
        final refreshToken = state.tokens?.refreshToken;
        if (token == null ||
            token.trim().isEmpty ||
            refreshToken == null ||
            refreshToken.trim().isEmpty) {
          completer.complete(null);
          return;
        }

        final refreshed = await ref
            .read(tokenRefresherProvider)
            .refresh(token: token, refreshToken: refreshToken);
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
