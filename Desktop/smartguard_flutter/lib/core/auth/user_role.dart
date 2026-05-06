enum UserRole {
  admin,
  homeowner,
  viewer,
}

UserRole parseUserRole(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  switch (v) {
    case 'admin':
      return UserRole.admin;
    case 'homeowner':
      return UserRole.homeowner;
    case 'viewer':
      return UserRole.viewer;
    default:
      return UserRole.viewer;
  }
}

String userRoleToWire(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.homeowner:
      return 'homeowner';
    case UserRole.viewer:
      return 'viewer';
  }
}
