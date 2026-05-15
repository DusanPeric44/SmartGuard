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
  });
}
