class AppConfig {
  static const String defaultApiBaseUrl = 'http://localhost:8080';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static bool get apiBaseUrlIsOverridden => apiBaseUrl != defaultApiBaseUrl;
}
