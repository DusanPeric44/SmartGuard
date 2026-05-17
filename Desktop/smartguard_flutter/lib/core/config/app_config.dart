class AppConfig {
  const AppConfig._();

  static const String defaultApiBaseUrl = 'http://localhost:5000';
  static const String defaultArchiveBaseUrl = defaultApiBaseUrl;
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

  static const String _configuredArchiveBaseUrl = String.fromEnvironment(
    'ARCHIVE_BASE_URL',
    defaultValue: defaultArchiveBaseUrl,
  );

  static String resolveApiBaseUrl([String? rawValue]) {
    final candidate = (rawValue ?? _configuredApiBaseUrl).trim();
    return candidate.isEmpty ? defaultApiBaseUrl : candidate;
  }

  static Uri parseApiBaseUri([String? rawValue]) {
    return Uri.parse(resolveApiBaseUrl(rawValue));
  }

  static String resolveArchiveBaseUrl([String? rawValue]) {
    final candidate = (rawValue ?? _configuredArchiveBaseUrl).trim();
    return candidate.isEmpty ? defaultArchiveBaseUrl : candidate;
  }

  static Uri parseArchiveBaseUri([String? rawValue]) {
    return Uri.parse(resolveArchiveBaseUrl(rawValue));
  }

  static String get apiBaseUrl => resolveApiBaseUrl();

  static Uri get apiBaseUri => parseApiBaseUri();

  static String get archiveBaseUrl => resolveArchiveBaseUrl();

  static Uri get archiveBaseUri => parseArchiveBaseUri();
}
