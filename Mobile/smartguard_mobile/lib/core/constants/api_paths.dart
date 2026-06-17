class ApiPaths {
  const ApiPaths._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh-token';

  static const String me = '/auth/me';
  static const String updateMe = '/users/me';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String pushToken = '/users/push-token';

  static const String knownPersonsPreferencesSearch =
      '/UserNotificationPreferences';
  static String userNotificationPreferences(String personId) =>
      '/UserNotificationPreferences/$personId';

  static const String devices = '/devices/my';
  static String deviceById(String id) => '/devices/$id';

  static const String dashboardMobile = '/dashboard/mobile';

  static const String alerts = '/Alerts';
  static String alertConfirm(int id) => '/Alerts/$id/confirm';
  static String alertDismiss(int id) => '/Alerts/$id/dismiss';

  static const String recordings = '/Recordings';
  static String recordingById(int id) => '/Recordings/$id';

  static const String notifications = '/api/notifications';
  static String notificationById(int id) => '/api/notifications/$id';
  static String notificationRead(int id) => '/api/notifications/$id/read';
  static const String notificationsReadAll = '/api/notifications/read-all';
}
