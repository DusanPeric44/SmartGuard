import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'push_notifications_handler.dart';
import 'push_preferences.dart';
import 'push_route_parser.dart';
import 'push_token_repository.dart';

final pushPreferencesProvider = Provider<PushPreferences>((ref) {
  return PushPreferences();
});

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return ApiPushTokenRepository(ref.read(dioProvider));
});

final pushNotificationsHandlerProvider = Provider<PushNotificationsHandler>((
  ref,
) {
  final handler = PushNotificationsHandler(
    preferences: ref.read(pushPreferencesProvider),
    tokenRepository: ref.read(pushTokenRepositoryProvider),
    routeParser: const PushRouteParser(),
  );

  ref.onDispose(() {
    unawaited(handler.dispose());
  });

  return handler;
});
