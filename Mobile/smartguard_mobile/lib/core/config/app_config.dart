class AppConfig {
  static const String defaultApiBaseUrl = 'http://10.0.2.2:5000';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static bool get apiBaseUrlIsOverridden => apiBaseUrl != defaultApiBaseUrl;

  static const bool allowBadCertificates = bool.fromEnvironment(
    'ALLOW_BAD_CERTS',
    defaultValue: false,
  );
}
