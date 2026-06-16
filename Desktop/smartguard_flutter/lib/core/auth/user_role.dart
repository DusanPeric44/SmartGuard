enum UserRole { admin, homeowner, viewer }

/// Centralized role string literals (wire format expected/returned by the API),
/// so role "magic strings" live in one place instead of being scattered.
class UserRoleWire {
  const UserRoleWire._();

  static const String admin = 'Admin';
  static const String homeowner = 'Home Owner';
  static const String viewer = 'Viewer';
}

UserRole parseUserRole(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  for (final role in UserRole.values) {
    if (role.name.toLowerCase() == v ||
        userRoleToWire(role).toLowerCase() == v) {
      return role;
    }
  }
  return UserRole.viewer;
}

String userRoleToWire(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return UserRoleWire.admin;
    case UserRole.homeowner:
      return UserRoleWire.homeowner;
    case UserRole.viewer:
      return UserRoleWire.viewer;
  }
}
