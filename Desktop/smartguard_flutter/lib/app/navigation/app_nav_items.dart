import 'package:flutter/material.dart';

class AppNavItem {
  const AppNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
}

const appNavItems = <AppNavItem>[
  AppNavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  ),
  AppNavItem(
    id: 'devices',
    label: 'Device Management',
    icon: Icons.videocam_outlined,
    route: '/devices',
  ),
  AppNavItem(
    id: 'users',
    label: 'Permissions',
    icon: Icons.people_alt_outlined,
    route: '/users',
  ),
  AppNavItem(
    id: 'recordings',
    label: 'Recordings',
    icon: Icons.video_library_outlined,
    route: '/recordings',
  ),
  AppNavItem(
    id: 'alarms',
    label: 'Alarm Center',
    icon: Icons.notifications_active_outlined,
    route: '/alarms',
  ),
  AppNavItem(
    id: 'known-persons',
    label: 'Known Persons',
    icon: Icons.verified_user_outlined,
    route: '/known-persons',
  ),
  AppNavItem(
    id: 'reports',
    label: 'PDF Reports',
    icon: Icons.picture_as_pdf_outlined,
    route: '/reports',
  ),
  AppNavItem(
    id: 'reference',
    label: 'Reference Data',
    icon: Icons.storage_outlined,
    route: '/reference',
  ),
  AppNavItem(
    id: 'audit',
    label: 'Audit Logs',
    icon: Icons.history_outlined,
    route: '/audit',
  ),
];
