const _dashboardChildren = <String, String>{
  'live-stream': '/live',
  'livestream': '/live',
  'recordings': '/archive',
  'recording-archive': '/archive',
  'known-persons': '/persons',
  'knownpersons': '/persons',
};

const _topLevelRoutes = <String, String>{
  'dashboard': '/dashboard',
  'home': '/dashboard',
  'live': '/live',
  'archive': '/archive',
  'alarms': '/alarms',
  'alarm-center': '/alarms',
  'alarmcenter': '/alarms',
  'persons': '/persons',
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
