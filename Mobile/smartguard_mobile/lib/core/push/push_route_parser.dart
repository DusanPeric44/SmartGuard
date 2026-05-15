class PushRouteParser {
  const PushRouteParser();

  String? routeFromData(Map<String, dynamic> data) {
    final raw = data['route']?.toString();
    if (raw == null) return null;
    final route = raw.trim();
    if (route.isEmpty) return null;
    if (!route.startsWith('/')) return null;
    return route;
  }
}
