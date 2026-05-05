import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_mapper.dart';

class DeepLinkHandler {
  DeepLinkHandler({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  bool _didHandleInitial = false;

  Future<void> start(GoRouter router) async {
    if (!_didHandleInitial) {
      _didHandleInitial = true;
      final initial = await _getInitialUri();
      if (initial != null) {
        _handleUri(router, initial);
      }
    }

    _subscription ??= _appLinks.uriLinkStream.listen((uri) {
      _handleUri(router, uri);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<Uri?> _getInitialUri() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      return null;
    }
  }

  void _handleUri(GoRouter router, Uri uri) {
    final location = mapDeepLinkToLocation(uri);
    if (location == null) return;

    if (router.routerDelegate.currentConfiguration.uri.toString() == location) {
      return;
    }

    router.go(location);
  }
}
