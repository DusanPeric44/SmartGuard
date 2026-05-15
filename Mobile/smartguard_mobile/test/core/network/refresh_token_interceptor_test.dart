import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/auth/session_manager.dart';
import 'package:smart_guard_flutter/core/auth/session_tokens.dart';
import 'package:smart_guard_flutter/core/network/interceptors/auth_header_interceptor.dart';
import 'package:smart_guard_flutter/core/network/interceptors/refresh_token_interceptor.dart';

void main() {
  test('refresh on 401 retries original request once', () async {
    final session = _FakeSessionManager(
      tokens: const SessionTokens(accessToken: 'A1', refreshToken: 'R1'),
      refreshed: const SessionTokens(accessToken: 'A2', refreshToken: 'R2'),
    );

    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = _Adapter((options) {
      final auth = options.headers['authorization']?.toString();
      if (auth == 'Bearer A1') {
        return _AdapterResponse(statusCode: 401, body: '');
      }
      if (auth == 'Bearer A2') {
        return _AdapterResponse(
          statusCode: 200,
          body: jsonEncode({'ok': true}),
        );
      }
      return _AdapterResponse(statusCode: 500, body: '');
    });

    dio.interceptors.add(AuthHeaderInterceptor(session: session));
    dio.interceptors.add(
      RefreshTokenInterceptor(session: session, dio: dio),
    );

    final response = await dio.get<Object?>('/protected');
    expect(response.data, isA<Map>());
    expect((response.data as Map)['ok'], true);
    expect(session.refreshCalls, 1);
    expect(session.tokens?.accessToken, 'A2');
  });

  test('concurrent 401 requests trigger single refresh', () async {
    final session = _FakeSessionManager(
      tokens: const SessionTokens(accessToken: 'A1', refreshToken: 'R1'),
      refreshed: const SessionTokens(accessToken: 'A2', refreshToken: 'R2'),
      refreshDelay: const Duration(milliseconds: 50),
    );

    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = _Adapter((options) {
      final auth = options.headers['authorization']?.toString();
      if (auth == 'Bearer A1') {
        return _AdapterResponse(statusCode: 401, body: '');
      }
      if (auth == 'Bearer A2') {
        return _AdapterResponse(statusCode: 200, body: jsonEncode({'ok': true}));
      }
      return _AdapterResponse(statusCode: 500, body: '');
    });

    dio.interceptors.add(AuthHeaderInterceptor(session: session));
    dio.interceptors.add(
      RefreshTokenInterceptor(session: session, dio: dio),
    );

    await Future.wait([
      dio.get<Object?>('/protected'),
      dio.get<Object?>('/protected'),
    ]);

    expect(session.refreshCalls, 1);
  });

  test('refresh failure logs out and surfaces error', () async {
    final session = _FakeSessionManager(
      tokens: const SessionTokens(accessToken: 'A1', refreshToken: 'R1'),
      refreshed: null,
    );

    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = _Adapter((_) {
      return _AdapterResponse(statusCode: 401, body: '');
    });

    dio.interceptors.add(AuthHeaderInterceptor(session: session));
    dio.interceptors.add(
      RefreshTokenInterceptor(session: session, dio: dio),
    );

    await expectLater(
      () => dio.get<Object?>('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(session.logoutCalls, 1);
  });
}

class _FakeSessionManager implements SessionManager {
  _FakeSessionManager({
    required this.tokens,
    required this.refreshed,
    this.refreshDelay = Duration.zero,
  });

  @override
  SessionTokens? tokens;

  final SessionTokens? refreshed;
  final Duration refreshDelay;

  int refreshCalls = 0;
  int logoutCalls = 0;

  Future<SessionTokens?>? _inFlight;

  @override
  Future<SessionTokens?> refreshTokensSingleFlight() {
    _inFlight ??= _doRefresh().whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  Future<SessionTokens?> _doRefresh() async {
    refreshCalls += 1;
    if (refreshDelay != Duration.zero) {
      await Future<void>.delayed(refreshDelay);
    }
    final next = refreshed;
    if (next != null) {
      await setTokens(next);
    }
    return next;
  }

  @override
  Future<void> setTokens(SessionTokens tokens) async {
    this.tokens = tokens;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    tokens = null;
  }
}

typedef _AdapterHandler = _AdapterResponse Function(RequestOptions options);

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);

  final _AdapterHandler _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = _handler(options);
    final headers = {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    };
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: headers,
    );
  }
}

class _AdapterResponse {
  const _AdapterResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
