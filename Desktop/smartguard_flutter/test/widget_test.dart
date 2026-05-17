import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smartguard_flutter/app/app.dart';
import 'package:smartguard_flutter/app/router/app_router.dart';
import 'package:smartguard_flutter/core/auth/auth_controller.dart';
import 'package:smartguard_flutter/core/auth/auth_repository.dart';
import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

void main() {
  testWidgets('login redirects user back to requested route', (
    WidgetTester tester,
  ) async {
    final tokenStore = MemoryTokenStore();
    late final AuthController auth;

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.uri.path;

          if (path == '/auth/login' && options.method == 'POST') {
            final raw = options.data?.toString() ?? '{}';
            final body = jsonDecode(raw) as Map<String, dynamic>;
            final email = body['email']?.toString() ?? '';
            final role = email.toLowerCase().startsWith('admin')
                ? 'admin'
                : 'viewer';

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode({'accessToken': 'stub-token', 'role': role}),
                ),
              ),
            );
            return;
          }

          if (path == '/auth/registration-key' && options.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(jsonEncode({'registrationKey': 'stub-key'})),
              ),
            );
            return;
          }

          if (path == '/devices/details/camera-01' && options.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode({
                    'device': {
                      'id': 'camera-01',
                      'name': 'Camera 01',
                      'ipAddress': '192.168.1.10',
                      'status': 'online',
                      'storageTotalGb': 512,
                      'storageUsedGb': 12,
                      'isActive': true,
                    },
                    'assignedUsers': [
                      {'id': 'u2', 'email': 'home01@example.com'},
                    ],
                  }),
                ),
              ),
            );
            return;
          }

          if (path == '/users' && options.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode([
                    {'id': 'u1', 'email': 'admin01@example.com'},
                    {'id': 'u2', 'email': 'home01@example.com'},
                  ]),
                ),
              ),
            );
            return;
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 404,
              data: utf8.encode(jsonEncode({'message': 'Not found'})),
            ),
          );
        },
      ),
    );

    final api = ApiClient(
      baseUri: Uri.parse('http://localhost:8080/'),
      dio: dio,
      tokenProvider: tokenStore.getToken,
      onUnauthorized: () async => auth.handleUnauthorized(),
    );

    auth = AuthController(
      repository: AuthRepository(api: api, tokenStore: tokenStore),
      tokenStore: tokenStore,
    );
    await auth.init();

    final router = buildRouter(
      initialLocation: '/devices/camera-01',
      auth: auth,
    );

    await tester.pumpWidget(
      SmartGuardRoot(router: router, auth: auth, api: api),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prijava'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await tester.pumpAndSettle();

    expect(find.text('Camera 01'), findsOneWidget);
    expect(find.text('Assigned users'), findsOneWidget);
  });

  testWidgets('non-admin user is blocked from using desktop app', (
    WidgetTester tester,
  ) async {
    final tokenStore = MemoryTokenStore();
    late final AuthController auth;

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.uri.path;

          if (path == '/auth/login' && options.method == 'POST') {
            final raw = options.data?.toString() ?? '{}';
            final body = jsonDecode(raw) as Map<String, dynamic>;
            final email = body['email']?.toString() ?? '';
            final role = email.toLowerCase().startsWith('admin')
                ? 'admin'
                : 'viewer';

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(
                  jsonEncode({'accessToken': 'stub-token', 'role': role}),
                ),
              ),
            );
            return;
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 404,
              data: utf8.encode(jsonEncode({'message': 'Not found'})),
            ),
          );
        },
      ),
    );

    final api = ApiClient(
      baseUri: Uri.parse('http://localhost:8080/'),
      dio: dio,
      tokenProvider: tokenStore.getToken,
      onUnauthorized: () async => auth.handleUnauthorized(),
    );

    auth = AuthController(
      repository: AuthRepository(api: api, tokenStore: tokenStore),
      tokenStore: tokenStore,
    );
    await auth.init();

    final router = buildRouter(initialLocation: '/dashboard', auth: auth);

    await tester.pumpWidget(
      SmartGuardRoot(router: router, auth: auth, api: api),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prijava'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'viewer01');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await tester.pumpAndSettle();

    expect(find.text('Pristup odbijen'), findsOneWidget);
    expect(find.textContaining('admin korisnicima'), findsOneWidget);
  });
}
