import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/push/push_route_parser.dart';

void main() {
  test('routeFromData returns valid route', () {
    const parser = PushRouteParser();
    final route = parser.routeFromData({'route': '/dashboard'});
    expect(route, '/dashboard');
  });

  test('routeFromData rejects invalid routes', () {
    const parser = PushRouteParser();
    expect(parser.routeFromData({}), isNull);
    expect(parser.routeFromData({'route': ''}), isNull);
    expect(parser.routeFromData({'route': 'dashboard'}), isNull);
  });
}
