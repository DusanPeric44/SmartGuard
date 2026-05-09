import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import 'session_tokens.dart';
import 'session_tokens_parser.dart';

abstract interface class TokenRefresher {
  Future<SessionTokens?> refresh({required String refreshToken});
}

class ApiTokenRefresher implements TokenRefresher {
  ApiTokenRefresher(this._dio, {this.path = ApiPaths.refresh});

  final Dio _dio;
  final String path;
  final _parser = const SessionTokensParser();

  @override
  Future<SessionTokens?> refresh({required String refreshToken}) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: {'refreshToken': refreshToken},
      );
      return _parser.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }
}
