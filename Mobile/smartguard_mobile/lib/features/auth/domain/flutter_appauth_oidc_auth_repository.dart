import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import 'auth_models.dart';
import 'oidc_auth_repository.dart';

class FlutterAppAuthOidcAuthRepository implements OidcAuthRepository {
  FlutterAppAuthOidcAuthRepository({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<AuthTokens?> signInWithGoogle() async {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/*$'), '');
    final startUri = Uri.parse('$base/auth/google/start');

    final completer = Completer<Uri>();
    StreamSubscription<Uri>? subscription;
    try {
      subscription = _appLinks.uriLinkStream.listen((uri) {
        if (completer.isCompleted) return;
        if (uri.scheme != 'com.smart.guard') return;
        final host = uri.host.trim().toLowerCase();
        final firstSegment = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.trim().toLowerCase()
            : '';
        if (host != 'callback' && firstSegment != 'callback') return;
        completer.complete(uri);
      });

      final didLaunch = await launchUrl(
        startUri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch) {
        throw const FormatException('Failed to open browser');
      }

      final callback = await completer.future.timeout(
        const Duration(minutes: 2),
      );

      final error = callback.queryParameters['error'];
      if (error != null && error.trim().isNotEmpty) {
        throw FormatException(error);
      }

      final access =
          (callback.queryParameters['token'] ??
                  callback.queryParameters['accessToken'] ??
                  callback.queryParameters['access_token'])
              ?.trim();
      final refresh =
          (callback.queryParameters['refreshToken'] ??
                  callback.queryParameters['refresh_token'])
              ?.trim();

      if (access == null || access.isEmpty) {
        throw const FormatException('Missing access token');
      }
      if (refresh == null || refresh.isEmpty) {
        throw const FormatException('Missing refresh token');
      }

      return AuthTokens(accessToken: access, refreshToken: refresh);
    } on TimeoutException {
      return null;
    } finally {
      await subscription?.cancel();
    }
  }
}
