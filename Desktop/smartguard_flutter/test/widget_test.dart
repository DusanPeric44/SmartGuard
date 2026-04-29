import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartguard_flutter/app/app.dart';
import 'package:smartguard_flutter/app/router/app_router.dart';
import 'package:smartguard_flutter/core/auth/auth_controller.dart';
import 'package:smartguard_flutter/core/auth/auth_repository.dart';
import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

void main() {
  testWidgets('login redirects user back to requested route', (WidgetTester tester) async {
    final tokenStore = MemoryTokenStore();
    late final AuthController auth;

    final api = ApiClient(
      baseUri: Uri.parse('http://localhost:8080/'),
      httpClient: MockClient((request) async => http.Response('{}', 200)),
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
      SmartGuardRoot(
        router: router,
        auth: auth,
        api: api,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prijava'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await tester.pumpAndSettle();

    expect(find.text('Device Details'), findsOneWidget);
  });
}
