import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/config/app_config.dart';

void main() {
  test(
    'AppConfig.apiBaseUrl koristi default kada API_BASE_URL nije definisan',
    () {
      if (AppConfig.apiBaseUrlIsOverridden) return;
      expect(AppConfig.apiBaseUrl, AppConfig.defaultApiBaseUrl);
    },
  );

  test('AppConfig.apiBaseUrl čita API_BASE_URL kada je definisan', () {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isEmpty) return;
    expect(AppConfig.apiBaseUrl, defined);
  });
}
