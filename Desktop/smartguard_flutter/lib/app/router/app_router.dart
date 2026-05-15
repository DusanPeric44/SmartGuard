import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/shell/app_shell.dart';
import 'package:smartguard_flutter/core/auth/auth_controller.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/auth/access_denied_screen.dart';
import 'package:smartguard_flutter/features/auth/login_screen.dart';
import 'package:smartguard_flutter/features/dashboard/dashboard_screen.dart';
import 'package:smartguard_flutter/features/devices/devices_screen.dart';
import 'package:smartguard_flutter/features/known_persons/known_persons_screen.dart';
import 'package:smartguard_flutter/features/permissions/permissions_screen.dart';
import 'package:smartguard_flutter/features/placeholder/placeholder_screen.dart';
import 'package:smartguard_flutter/features/recordings/recordings_screen.dart';
import 'package:smartguard_flutter/features/reference_data/reference_data_screen.dart';

GoRouter buildRouter({
  required String initialLocation,
  required AuthController auth,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isInitializing) return null;

      final isLoggingIn = state.matchedLocation == '/login';
      final isAccessDenied = state.matchedLocation == '/access-denied';

      if (!auth.isAuthenticated) {
        if (isLoggingIn) return null;
        if (isAccessDenied) return '/login';
        return Uri(
          path: '/login',
          queryParameters: <String, String>{'from': state.uri.toString()},
        ).toString();
      }

      final isAdmin = auth.role == UserRole.admin;
      if (!isAdmin) {
        return isAccessDenied ? null : '/access-denied';
      }

      if (isAccessDenied) return '/dashboard';

      if (isLoggingIn) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty) ? from : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentUri: state.uri, child: child),
        routes: [
          GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DevicesScreen(),
            routes: [
              GoRoute(
                path: ':deviceId',
                name: 'device-details',
                builder: (context, state) => DeviceDetailsScreen(
                  deviceId: state.pathParameters['deviceId'] ?? 'unknown',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            builder: (context, state) => const PermissionsScreen(),
          ),
          GoRoute(
            path: '/recordings',
            name: 'recordings',
            builder: (context, state) => const RecordingsScreen(),
          ),
          GoRoute(
            path: '/alarms',
            name: 'alarms',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Alarm Center'),
          ),
          GoRoute(
            path: '/known-persons',
            name: 'known-persons',
            builder: (context, state) => const KnownPersonsScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'PDF Reports'),
          ),
          GoRoute(
            path: '/reference',
            name: 'reference',
            builder: (context, state) => const ReferenceDataScreen(),
          ),
          GoRoute(
            path: '/audit',
            name: 'audit',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Audit Logs'),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _NotFoundScreen(uri: state.uri),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Route not found: ${uri.toString()}')),
    );
  }
}
