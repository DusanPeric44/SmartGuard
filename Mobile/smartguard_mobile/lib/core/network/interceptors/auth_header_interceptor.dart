import 'package:dio/dio.dart';

import '../../auth/session_manager.dart';

class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor({required SessionManager session})
    : _session = session;

  final SessionManager _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.tokens?.accessToken;
    if (token == null || token.trim().isEmpty) {
      handler.next(options);
      return;
    }

    final hasAuth = options.headers.keys.any(
      (k) => k.toString().toLowerCase() == 'authorization',
    );
    if (hasAuth) {
      handler.next(options);
      return;
    }

    options.headers['authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
