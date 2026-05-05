import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/core/network/api_error.dart';

void main() {
  group('ApiClient', () {
    test('invokes unauthorized handler on 401 response', () async {
      var unauthorizedCalled = false;

      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:8080/'),
        httpClient: MockClient((request) async {
          return http.Response('{"message":"Token expired"}', 401);
        }),
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
