import 'package:flutter_test/flutter_test.dart';
import 'package:smartguard_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('falls back to default API base URL for empty value', () {
      expect(
        AppConfig.resolveApiBaseUrl(''),
        AppConfig.defaultApiBaseUrl,
      );
    });

    test('parses custom API base URL', () {
      final uri = AppConfig.parseApiBaseUri('https://example.com/api');
      expect(uri.toString(), 'https://example.com/api');
    });
  });
}
