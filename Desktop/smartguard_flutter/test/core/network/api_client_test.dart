import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/core/network/api_error.dart';

void main() {
  group('ApiClient', () {
    test('invokes unauthorized handler on 401 response', () async {
      var unauthorizedCalled = false;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 401,
                data: utf8.encode('{"message":"Token expired"}'),
              ),
            );
          },
        ),
      );

      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:8080/'),
        dio: dio,
        onUnauthorized: () async {
          unauthorizedCalled = true;
        },
      );

      await expectLater(
        client.get<Object?>('/secure'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.error.kind,
            'kind',
            ApiErrorKind.unauthorized,
          ),
        ),
      );
      expect(unauthorizedCalled, isTrue);
    });

    test('refreshes token and retries request on 401', () async {
      var token = 'old-token';
      var refreshToken = 'old-refresh';
      var secureCalls = 0;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.uri.path == '/secure') {
              secureCalls++;
              if (secureCalls == 1) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: utf8.encode('{"message":"Token expired"}'),
                  ),
                );
                return;
              }

              expect(options.headers['Authorization'], 'Bearer new-token');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: utf8.encode('{"ok":true}'),
                ),
              );
              return;
            }

            if (options.uri.path == '/auth/refresh-token') {
              expect(options.headers.containsKey('Authorization'), isFalse);
              final raw = options.data?.toString() ?? '{}';
              final body = jsonDecode(raw) as Map<String, dynamic>;
              expect(body['token'], 'old-token');
              expect(body['refreshToken'], 'old-refresh');

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: utf8.encode(
                    jsonEncode({'token': 'new-token', 'refreshToken': 'new-refresh'}),
                  ),
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 404,
                data: utf8.encode('{"message":"Not found"}'),
              ),
            );
          },
        ),
      );

      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:8080/'),
        dio: dio,
        tokenProvider: () async => token,
        refreshTokenProvider: () async => refreshToken,
        onTokenRefreshed: (t, rt) async {
          token = t;
          refreshToken = rt;
        },
      );

      final res = await client.get<Object?>('/secure');
      expect(res, isA<Map>());
      expect(secureCalls, 2);
      expect(token, 'new-token');
      expect(refreshToken, 'new-refresh');
    });

    test('invokes unauthorized handler when refresh fails', () async {
      var unauthorizedCalled = false;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.uri.path == '/secure') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: utf8.encode('{"message":"Token expired"}'),
                ),
              );
              return;
            }

            if (options.uri.path == '/auth/refresh-token') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: utf8.encode('{"message":"Refresh expired"}'),
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 404,
                data: utf8.encode('{"message":"Not found"}'),
              ),
            );
          },
        ),
      );

      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:8080/'),
        dio: dio,
        tokenProvider: () async => 'old-token',
        refreshTokenProvider: () async => 'old-refresh',
        onTokenRefreshed: (token, refreshToken) async {},
        onUnauthorized: () async {
          unauthorizedCalled = true;
        },
      );

      await expectLater(
        client.get<Object?>('/secure'),
        throwsA(isA<ApiException>()),
      );
      expect(unauthorizedCalled, isTrue);
    });
  });
}
