import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/auth/session_state.dart';
import '../../core/constants/app_routes.dart';
import '../../features/alarm_center/presentation/alarm_center_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/known_persons/presentation/known_persons_screen.dart';
import '../../features/live_stream/presentation/live_stream_screen.dart';
import '../../features/live_stream/presentation/live_stream_fullscreen_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recording_archive/presentation/recording_archive_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;

      if (session.status == SessionStatus.unknown) {
        return null;
      }

      final isAuthed = session.isAuthenticated;
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
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
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
                routes: [
                  GoRoute(
                    path: 'live-stream',
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
                  GoRoute(
                    path: 'recordings',
                    builder: (context, state) => const RecordingArchiveScreen(),
                  ),
                  GoRoute(
                    path: 'known-persons',
                    builder: (context, state) => const KnownPersonsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alarmCenter,
                builder: (context, state) => const AlarmCenterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
