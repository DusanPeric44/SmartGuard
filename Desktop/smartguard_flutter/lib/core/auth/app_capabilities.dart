import 'package:smartguard_flutter/core/auth/user_role.dart';

class AppCapabilities {
  const AppCapabilities({
    required this.canStream,
    required this.canDownload,
    required this.canManageUsers,
    required this.canEditReferenceData,
    required this.canManageDevices,
  });

  final bool canStream;
  final bool canDownload;
  final bool canManageUsers;
  final bool canEditReferenceData;
  final bool canManageDevices;

  static AppCapabilities fromRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AppCapabilities(
          canStream: true,
          canDownload: true,
          canManageUsers: true,
          canEditReferenceData: true,
          canManageDevices: true,
        );
      case UserRole.homeowner:
        return const AppCapabilities(
          canStream: true,
          canDownload: true,
          canManageUsers: false,
          canEditReferenceData: false,
          canManageDevices: true,
        );
      case UserRole.viewer:
        return const AppCapabilities(
          canStream: true,
          canDownload: false,
          canManageUsers: false,
          canEditReferenceData: false,
          canManageDevices: false,
        );
    }
  }
}
