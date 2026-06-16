import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/auth/session_state.dart';
import '../../core/constants/app_routes.dart';
import '../../features/alarm_center/presentation/alarm_center_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/devices/presentation/device_detail_screen.dart';
import '../../features/known_persons/presentation/known_persons_screen.dart';
import '../../features/live_stream/presentation/live_stream_screen.dart';
import '../../features/live_stream/presentation/live_stream_fullscreen_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recording_archive/presentation/recording_archive_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;

      if (session.status == SessionStatus.unknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      final isAuthed = session.isAuthenticated;
      if (isSplash) {
        return isAuthed ? AppRoutes.dashboard : AppRoutes.login;
      }
      if (!isAuthed && !isLoggingIn && !isRegistering) {
        return AppRoutes.login;
      }
      if (isAuthed && (isLoggingIn || isRegistering)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) =>
            const Scaffold(body: ProfileScreen(showHeader: false)),
      ),
      GoRoute(
        path: AppRoutes.deviceDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DeviceDetailScreen(deviceId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            location: state.uri.toString(),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.live,
                builder: (context, state) {
                  final deviceId = state.uri.queryParameters['deviceId'];
                  return LiveStreamScreen(initialDeviceId: deviceId);
                },
                routes: [
                  GoRoute(
                    path: 'fullscreen',
                    builder: (context, state) =>
                        const LiveStreamFullscreenScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.archive,
                builder: (context, state) => const RecordingArchiveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alarms,
                builder: (context, state) => const AlarmCenterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.persons,
                builder: (context, state) => const KnownPersonsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
