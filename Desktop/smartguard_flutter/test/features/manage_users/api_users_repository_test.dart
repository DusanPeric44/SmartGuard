import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/manage_users/data/api_users_repository.dart';

void main() {
  group('ApiUsersRepository', () {
    test('list sends PageNum/PageSize/term and decodes {count,result}', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.uri.path, '/users/');
            expect(options.uri.queryParameters['PageNum'], '2');
            expect(options.uri.queryParameters['PageSize'], '50');
            expect(options.uri.queryParameters['term'], 'john');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode({
                    'count': 1,
                    'result': [
                      {
                        'id': 'u1',
                        'email': 'john@example.com',
                        'role': 'admin',
                      },
                    ],
                  }),
                ),
              ),
            );
          },
        ),
      );

      final api = ApiClient(baseUri: Uri.parse('http://localhost:8080/'), dio: dio);
      final repo = ApiUsersRepository(api: api);

      final res = await repo.list(term: 'john', pageNum: 2, pageSize: 50);
      expect(res.count, 1);
      expect(res.result, hasLength(1));
      expect(res.result.first.id, 'u1');
      expect(res.result.first.email, 'john@example.com');
      expect(res.result.first.role, UserRole.admin);
    });

    test('list omits term when empty', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.uri.queryParameters['PageNum'], '1');
            expect(options.uri.queryParameters['PageSize'], '20');
            expect(options.uri.queryParameters.containsKey('term'), isFalse);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode({
                    'count': 0,
                    'result': [],
                  }),
                ),
              ),
            );
          },
        ),
      );

      final api = ApiClient(baseUri: Uri.parse('http://localhost:8080/'), dio: dio);
      final repo = ApiUsersRepository(api: api);

      final res = await repo.list(term: '', pageNum: 1, pageSize: 20);
      expect(res.count, 0);
      expect(res.result, isEmpty);
    });
  });
}

