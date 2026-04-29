const _dashboardChildren = <String, String>{
  'live-stream': '/dashboard/live-stream',
  'livestream': '/dashboard/live-stream',
  'recordings': '/dashboard/recordings',
  'recording-archive': '/dashboard/recordings',
  'known-persons': '/dashboard/known-persons',
  'knownpersons': '/dashboard/known-persons',
  'settings': '/dashboard/settings',
};

const _topLevelRoutes = <String, String>{
  'dashboard': '/dashboard',
  'home': '/dashboard',
  'alarm-center': '/alarm-center',
  'alarmcenter': '/alarm-center',
  'notifications': '/notifications',
  'profile': '/profile',
  'login': '/login',
};

String? mapDeepLinkToLocation(Uri uri) {
  final segments = _canonicalSegments(uri);
  if (segments.isEmpty) return null;

  final first = segments.first;
  if (first == 'dashboard' || first == 'home') {
    if (segments.length == 1) return '/dashboard';
    return _dashboardChildren[segments[1]];
  }

  if (_dashboardChildren.containsKey(first)) return _dashboardChildren[first];
  return _topLevelRoutes[first];
}

List<String> _canonicalSegments(Uri uri) {
  final segments = uri.pathSegments
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toList(growable: false);

  final host = uri.host.trim().toLowerCase();
  if (host.isEmpty) return segments;

  final hostLooksLikeDomain = host.contains('.');
  final hostIsKnown =
      _topLevelRoutes.containsKey(host) || _dashboardChildren.containsKey(host);
  if (hostLooksLikeDomain && !hostIsKnown) return segments;

  if (segments.isEmpty) return [host];
  if (hostIsKnown) return [host, ...segments];
  return segments;
}
