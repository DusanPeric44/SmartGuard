import 'package:dio/dio.dart';

import '../../auth/session_manager.dart';
import '../../auth/session_tokens.dart';

class RefreshTokenInterceptor extends QueuedInterceptor {
  RefreshTokenInterceptor({
    required SessionManager session,
    required Dio dio,
  }) : _session = session,
       _dio = dio;

  final SessionManager _session;
  final Dio _dio;

  static const String _didRetryKey = 'didRetry';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    final didRetry = options.extra[_didRetryKey] == true;
    if (didRetry) {
      handler.next(err);
      return;
    }

    if (_isRefreshRequest(options)) {
      handler.next(err);
      return;
    }

    final currentAccessToken = _session.tokens?.accessToken.trim();
    final requestAccessToken = _bearerTokenFromHeaders(options.headers);
    if (currentAccessToken != null &&
        currentAccessToken.isNotEmpty &&
        requestAccessToken != null &&
        requestAccessToken != currentAccessToken) {
      options.extra[_didRetryKey] = true;
      options.headers['authorization'] = 'Bearer $currentAccessToken';

      try {
        final response = await _dio.fetch(options);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    final refreshed = await _tryRefresh();
    if (refreshed == null) {
      await _session.logout();
      handler.next(err);
      return;
    }

    options.extra[_didRetryKey] = true;
    options.headers['authorization'] = 'Bearer ${refreshed.accessToken}';

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isRefreshRequest(RequestOptions options) {
    final p = options.path.toLowerCase();
    return p.contains('/auth/refresh-token') || p.endsWith('auth/refresh-token');
  }

  Future<SessionTokens?> _tryRefresh() {
    return _session.refreshTokensSingleFlight();
  }

  String? _bearerTokenFromHeaders(Map<String, dynamic> headers) {
    Object? value;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        value = entry.value;
        break;
      }
    }
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    const prefix = 'bearer ';
    if (raw.toLowerCase().startsWith(prefix)) {
      final token = raw.substring(prefix.length).trim();
      return token.isEmpty ? null : token;
    }
    return null;
  }
}
