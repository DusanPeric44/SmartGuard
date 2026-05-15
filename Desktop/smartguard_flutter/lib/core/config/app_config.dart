class AppConfig {
  const AppConfig._();

  static const String defaultApiBaseUrl = 'http://localhost:5000';
  static const String appScheme = 'smartguard';
  static const bool enableStubAuth = bool.fromEnvironment(
    'USE_STUB_AUTH',
    defaultValue: false,
  );
  static const bool enableStubData = bool.fromEnvironment(
    'USE_STUB_DATA',
    defaultValue: false,
  );

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static String resolveApiBaseUrl([String? rawValue]) {
    final candidate = (rawValue ?? _configuredApiBaseUrl).trim();
    return candidate.isEmpty ? defaultApiBaseUrl : candidate;
  }

  static Uri parseApiBaseUri([String? rawValue]) {
    return Uri.parse(resolveApiBaseUrl(rawValue));
  }

  static String get apiBaseUrl => resolveApiBaseUrl();

  static Uri get apiBaseUri => parseApiBaseUri();
}
