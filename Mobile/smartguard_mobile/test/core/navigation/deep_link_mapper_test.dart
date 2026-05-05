import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/navigation/deep_link_mapper.dart';

void main() {
  group('mapDeepLinkToLocation', () {
    test('maps top-level https path to route', () {
      final uri = Uri.parse('https://example.com/notifications');
      expect(mapDeepLinkToLocation(uri), '/notifications');
    });

    test('maps custom scheme host to top-level route', () {
      final uri = Uri.parse('smartguard://alarm-center');
      expect(mapDeepLinkToLocation(uri), '/alarm-center');
    });

    test('maps nested dashboard child from https path', () {
      final uri = Uri.parse('https://example.com/dashboard/live-stream');
      expect(mapDeepLinkToLocation(uri), '/dashboard/live-stream');
    });

    test('maps nested dashboard child from custom scheme host+path', () {
      final uri = Uri.parse('smartguard://dashboard/recordings');
      expect(mapDeepLinkToLocation(uri), '/dashboard/recordings');
    });

    test('returns null for unknown link', () {
      final uri = Uri.parse('https://example.com/something-else');
      expect(mapDeepLinkToLocation(uri), isNull);
    });
  });
}
