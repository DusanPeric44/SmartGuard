class AppConfig {
  static const String defaultApiBaseUrl = 'http://10.0.2.2:5000';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static bool get apiBaseUrlIsOverridden => apiBaseUrl != defaultApiBaseUrl;

  static const String defaultArchiveBaseUrl = apiBaseUrl;
  static const String archiveBaseUrl = String.fromEnvironment(
    'ARCHIVE_BASE_URL',
    defaultValue: defaultArchiveBaseUrl,
  );

  static const String defaultNotificationsBaseUrl = 'http://10.0.2.2:5002';
  static const String notificationsBaseUrl = String.fromEnvironment(
    'NOTIFICATIONS_BASE_URL',
    defaultValue: defaultNotificationsBaseUrl,
  );

  static const bool allowBadCertificates = bool.fromEnvironment(
    'ALLOW_BAD_CERTS',
    defaultValue: false,
  );
}
