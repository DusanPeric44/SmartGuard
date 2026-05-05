import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/auth/session_tokens.dart';
import 'package:smart_guard_flutter/core/network/auth_http_transport.dart';
import 'package:smart_guard_flutter/core/network/http_transport.dart';

import '../auth/fake_session_manager.dart';
import 'fake_http_transport.dart';

void main() {
  test('401 -> refresh -> retry sa novim tokenom', () async {
    final session = FakeSessionManager(
      initialTokens: const SessionTokens(
        accessToken: 'old',
        refreshToken: 'r1',
      ),
      refreshResult: const SessionTokens(
        accessToken: 'new',
        refreshToken: 'r2',
      ),
    );

    var call = 0;
    final inner = FakeHttpTransport((request) async {
      call += 1;
      if (call == 1) {
        return HttpTransportResponse(
          statusCode: 401,
          headers: const {'content-type': 'application/json'},
          bodyBytes: utf8.encode(jsonEncode({'message': 'unauthorized'})),
        );
      }

      return HttpTransportResponse(
        statusCode: 200,
        headers: const {'content-type': 'application/json'},
        bodyBytes: utf8.encode(jsonEncode({'ok': true})),
      );
    });

    final transport = AuthHttpTransport(inner: inner, session: session);
    final response = await transport.send(
      HttpTransportRequest(
        method: 'GET',
        uri: Uri.parse('https://example.com/protected'),
        headers: const {},
        timeout: const Duration(seconds: 1),
      ),
    );

    expect(response.statusCode, 200);
    expect(inner.requests.length, 2);
    expect(inner.requests[0].headers['authorization'], 'Bearer old');
    expect(inner.requests[1].headers['authorization'], 'Bearer new');
    expect(session.refreshCalls, 1);
    expect(session.logoutCalls, 0);
  });

  test('401 -> refresh fail -> logout bez retry', () async {
    final session = FakeSessionManager(
      initialTokens: const SessionTokens(
        accessToken: 'old',
        refreshToken: 'r1',
      ),
      refreshResult: null,
    );

    final inner = FakeHttpTransport((request) async {
      return HttpTransportResponse(
        statusCode: 401,
        headers: const {'content-type': 'application/json'},
        bodyBytes: utf8.encode(jsonEncode({'message': 'unauthorized'})),
      );
    });

    final transport = AuthHttpTransport(inner: inner, session: session);
    final response = await transport.send(
      HttpTransportRequest(
        method: 'GET',
        uri: Uri.parse('https://example.com/protected'),
        headers: const {},
        timeout: const Duration(seconds: 1),
      ),
    );

    expect(response.statusCode, 401);
    expect(inner.requests.length, 1);
    expect(session.refreshCalls, 1);
    expect(session.logoutCalls, 1);
  });
}
