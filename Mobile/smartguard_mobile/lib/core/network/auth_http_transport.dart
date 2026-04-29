import '../auth/session_manager.dart';
import '../auth/session_tokens.dart';
import 'http_transport.dart';

class AuthHttpTransport implements HttpTransport {
  AuthHttpTransport({
    required HttpTransport inner,
    required SessionManager session,
  }) : _inner = inner,
       _session = session;

  final HttpTransport _inner;
  final SessionManager _session;

  @override
  Future<HttpTransportResponse> send(HttpTransportRequest request) {
    return _send(request, didRetry: false);
  }

  Future<HttpTransportResponse> _send(
    HttpTransportRequest request, {
    required bool didRetry,
  }) async {
    final initial = await _inner.send(_withAccessTokenIfMissing(request));
    if (initial.statusCode != 401) return initial;
    if (didRetry) return initial;

    SessionTokens? refreshed;
    try {
      refreshed = await _session.refreshTokensSingleFlight();
    } catch (_) {
      refreshed = null;
    }

    if (refreshed == null) {
      await _session.logout();
      return initial;
    }

    final retry = HttpTransportRequest(
      method: request.method,
      uri: request.uri,
      headers: Map.unmodifiable({
        ...request.headers,
        'authorization': 'Bearer ${refreshed.accessToken}',
      }),
      timeout: request.timeout,
      bodyBytes: request.bodyBytes,
    );

    return _send(retry, didRetry: true);
  }

  HttpTransportRequest _withAccessTokenIfMissing(HttpTransportRequest request) {
    final token = _session.tokens?.accessToken;
    if (token == null || token.trim().isEmpty) return request;

    final hasAuth = request.headers.keys.any(
      (k) => k.toLowerCase() == 'authorization',
    );
    if (hasAuth) return request;

    return HttpTransportRequest(
      method: request.method,
      uri: request.uri,
      headers: Map.unmodifiable({
        ...request.headers,
        'authorization': 'Bearer $token',
      }),
      timeout: request.timeout,
      bodyBytes: request.bodyBytes,
    );
  }
}
