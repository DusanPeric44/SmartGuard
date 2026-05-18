import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../auth/session_state.dart';
import 'push_preferences.dart';
import 'push_route_parser.dart';
import 'push_token_repository.dart';

class PushNotificationsHandler {
  PushNotificationsHandler({
    required PushPreferences preferences,
    required PushTokenRepository tokenRepository,
    required PushRouteParser routeParser,
  }) : _preferences = preferences,
       _tokenRepository = tokenRepository,
       _routeParser = routeParser;

  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  final PushPreferences _preferences;
  final PushTokenRepository _tokenRepository;
  final PushRouteParser _routeParser;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messageSub = <StreamSubscription<Object?>>[];

  GoRouter? _router;
  bool _started = false;
  int _notificationId = 0;

  ProviderSubscription<SessionState>? _sessionSub;
  SessionController? _session;

  Future<void> start(WidgetRef ref, GoRouter router) async {
    if (_started) return;
    _started = true;
    _router = router;

    if (_isFlutterTest || kIsWeb) return;

    _session = ref.read(sessionControllerProvider.notifier);

    await _ensureFirebaseInitialized();
    await _initLocalNotifications();

    _sessionSub = ref.listenManual<SessionState>(sessionControllerProvider, (
      _,
      next,
    ) {
      if (next.isAuthenticated) {
        unawaited(_onAuthenticated());
      }
    });

    _messageSub.add(
      FirebaseMessaging.onMessage.listen((m) {
        unawaited(_showForegroundNotification(m));
      }),
    );
    _messageSub.add(
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        unawaited(_handleOpen(m));
      }),
    );
    _messageSub.add(
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        unawaited(_syncTokenWithBackendIfEnabled());
      }),
    );

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _handleOpen(initial);
      }
    } catch (_) {}
  }

  Future<void> onPushEnabledChanged(bool enabled) async {
    if (_isFlutterTest || kIsWeb) return;
    await _preferences.setEnabled(enabled);

    if (!enabled) {
      await FirebaseMessaging.instance.deleteToken();
      await _preferences.clearPendingRoute();
      return;
    }

    await _requestAndroidNotificationPermission();
    await _syncTokenWithBackendIfEnabled();
  }

  Future<void> dispose() async {
    if (_isFlutterTest || kIsWeb) return;
    for (final sub in _messageSub) {
      await sub.cancel();
    }
    _messageSub.clear();
    _sessionSub?.close();
  }

  Future<void> _onAuthenticated() async {
    final enabled = await _preferences.loadEnabled();
    if (enabled) {
      await _requestAndroidNotificationPermission();
      await _syncTokenWithBackendIfEnabled();
    }
    await _flushPendingRouteIfAny();
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final route = resp.payload;
        if (route == null || route.trim().isEmpty) return;
        _router?.go(route);
      },
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      'alerts',
      'Alerts',
      description: 'SmartGuard notifications',
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
  }

  Future<void> _requestAndroidNotificationPermission() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    try {
      await android.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> _syncTokenWithBackendIfEnabled() async {
    final enabled = await _preferences.loadEnabled();
    if (!enabled) return;

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      token = null;
    }
    if (token == null || token.trim().isEmpty) return;

    final session = _session;
    if (session == null || session.tokens == null) return;

    final platform = Platform.isAndroid ? 'android' : Platform.operatingSystem;
    try {
      await _tokenRepository.registerToken(token: token, platform: platform);
    } catch (_) {}
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final route = _routeParser.routeFromData(data);

    final title =
        message.notification?.title ??
        data['title']?.toString() ??
        'SmartGuard';
    final body = message.notification?.body ?? data['body']?.toString() ?? '';

    final androidDetails = AndroidNotificationDetails(
      'alerts',
      'Alerts',
      channelDescription: 'SmartGuard notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);
    final id = _notificationId = (_notificationId + 1) & 0x7fffffff;

    try {
      await _localNotifications.show(id, title, body, details, payload: route);
    } catch (_) {}
  }

  Future<void> _handleOpen(RemoteMessage message) async {
    final router = _router;
    if (router == null) return;

    final data = Map<String, dynamic>.from(message.data);
    final route = _routeParser.routeFromData(data);
    if (route == null) return;

    final session = _session;
    if (session != null && session.tokens != null) {
      router.go(route);
      return;
    }

    await _preferences.setPendingRoute(route);
    router.go('/login');
  }

  Future<void> _flushPendingRouteIfAny() async {
    final router = _router;
    if (router == null) return;

    final pending = await _preferences.loadPendingRoute();
    if (pending == null || pending.trim().isEmpty) return;

    final session = _session;
    if (session != null && session.tokens != null) {
      await _preferences.clearPendingRoute();
      router.go(pending);
    }
  }
}
