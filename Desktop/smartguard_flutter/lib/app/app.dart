import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/app/router/app_router.dart';
import 'package:smartguard_flutter/app/theme/app_theme.dart';
import 'package:smartguard_flutter/core/auth/auth_controller.dart';
import 'package:smartguard_flutter/core/auth/auth_repository.dart';
import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

class SmartGuardApp extends StatefulWidget {
  const SmartGuardApp({super.key});

  @override
  State<SmartGuardApp> createState() => _SmartGuardAppState();
}

class _SmartGuardAppState extends State<SmartGuardApp> {
  final _appLinks = AppLinks();
  SmartGuardRoot? _root;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    Uri? initialUri;
    try {
      initialUri = await _appLinks.getInitialLink().timeout(
        const Duration(milliseconds: 200),
      );
    } catch (_) {
      initialUri = null;
    }

    final initialLocation = mapDeepLinkToLocation(initialUri) ?? '/dashboard';
    final tokenStore = await _createTokenStore();

    late final AuthController auth;
    final api = ApiClient(
      baseUri: AppConfig.apiBaseUri,
      tokenProvider: tokenStore.getToken,
      refreshTokenProvider: tokenStore.getRefreshToken,
      onTokenRefreshed: (token, refreshToken) async {
        await tokenStore.setToken(token);
        await tokenStore.setRefreshToken(refreshToken);
      },
      onUnauthorized: () async => auth.handleUnauthorized(),
    );
    final authRepository = AuthRepository(api: api, tokenStore: tokenStore);
    auth = AuthController(repository: authRepository, tokenStore: tokenStore);
    await auth.init();

    final router = buildRouter(initialLocation: initialLocation, auth: auth);

    try {
      _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
        final location = mapDeepLinkToLocation(uri);
        if (location != null) {
          router.go(location);
        }
      });
    } catch (_) {
      _deepLinkSubscription = null;
    }

    if (!mounted) return;
    setState(() {
      _root = SmartGuardRoot(router: router, auth: auth, api: api);
    });
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null) {
      return MaterialApp(
        title: 'SmartGuard',
        theme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return root;
  }
}

class SmartGuardRoot extends StatelessWidget {
  const SmartGuardRoot({
    super.key,
    required this.router,
    required this.auth,
    required this.api,
  });

  final GoRouter router;
  final AuthController auth;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      api: api,
      child: MaterialApp.router(
        title: 'SmartGuard',
        theme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}

String? mapDeepLinkToLocation(Uri? uri) {
  if (uri == null) return null;

  final normalized = _normalizeDeepLinkPath(uri);
  // TODO(rs2): Prosiriti deep link mapping za dodatne feature rute iz plana.

  if (normalized == '/dashboard') {
    return normalized;
  }
  if (normalized == '/devices' || normalized.startsWith('/devices/')) {
    return normalized;
  }
  if (normalized == '/reports' || normalized.startsWith('/reports/')) {
    return normalized;
  }

  return null;
}

String _normalizeDeepLinkPath(Uri uri) {
  final host = uri.host.trim();
  final path = uri.path.trim();
  if (host.isNotEmpty) {
    if (path.isEmpty || path == '/') {
      return '/$host';
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '/$host$normalizedPath';
  }
  if (path.isNotEmpty && path != '/') {
    return path.startsWith('/') ? path : '/$path';
  }
  return '/';
}

Future<TokenStore> _createTokenStore() async {
  try {
    return await SharedPrefsTokenStore.create();
  } catch (_) {
    return MemoryTokenStore();
  }
}
