import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/session_controller.dart';
import 'core/auth/session_state.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/deep_link_handler.dart';
import 'core/push/push_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/alarm_center/application/alarm_center_controller.dart';
import 'features/dashboard/application/dashboard_controller.dart';
import 'features/devices/application/devices_controller.dart';
import 'features/known_persons/application/known_persons_controller.dart';
import 'features/live_stream/application/live_stream_controller.dart';
import 'features/notifications/application/notifications_controller.dart';
import 'features/profile/application/profile_controller.dart';
import 'features/recording_archive/application/recording_archive_controller.dart';

class SmartGuardApp extends ConsumerStatefulWidget {
  const SmartGuardApp({super.key});

  @override
  ConsumerState<SmartGuardApp> createState() => _SmartGuardAppState();
}

class _SmartGuardAppState extends ConsumerState<SmartGuardApp> {
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();

  @override
  void initState() {
    super.initState();

    ref.listenManual(sessionControllerProvider, (previous, next) {
      final loggedOut =
          previous?.status == SessionStatus.authenticated &&
          next.status != SessionStatus.authenticated;

      final tokenChanged =
          previous?.tokens?.accessToken != next.tokens?.accessToken;

      if (!loggedOut && !tokenChanged) return;

      ref
        ..invalidate(profileControllerProvider)
        ..invalidate(devicesControllerProvider)
        ..invalidate(dashboardControllerProvider)
        ..invalidate(knownPersonsControllerProvider)
        ..invalidate(alarmCenterControllerProvider)
        ..invalidate(liveStreamControllerProvider)
        ..invalidate(recordingArchiveControllerProvider)
        ..invalidate(notificationsControllerProvider);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(goRouterProvider);
      _deepLinkHandler.start(router);
      ref.read(pushNotificationsHandlerProvider).start(ref, router);
    });
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appTitle,
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
