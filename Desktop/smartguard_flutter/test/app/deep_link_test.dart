import 'package:flutter_test/flutter_test.dart';
import 'package:smartguard_flutter/app/app.dart';

void main() {
  group('mapDeepLinkToLocation', () {
    test('maps dashboard deep link', () {
      expect(
        mapDeepLinkToLocation(Uri.parse('smartguard://dashboard')),
        '/dashboard',
      );
    });

    test('maps device detail deep link with host and path', () {
      expect(
        mapDeepLinkToLocation(Uri.parse('smartguard://devices/camera-01')),
        '/devices/camera-01',
      );
    });

    test('maps reports deep link', () {
      expect(
        mapDeepLinkToLocation(Uri.parse('smartguard://reports')),
        '/reports',
      );
    });

    test('ignores unsupported deep links', () {
      expect(
        mapDeepLinkToLocation(Uri.parse('smartguard://users')),
        isNull,
      );
    });
  });
}
