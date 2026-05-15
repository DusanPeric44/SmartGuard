class ApiPaths {
  const ApiPaths._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  static const String me = '/users/me';
  static const String updateMe = '/users/me';
  static const String changePassword = '/users/change-password';

  static const String devices = '/devices/my';
  static String deviceById(String id) => '/devices/$id';
}
