import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import '../network/api_error.dart';
import 'session_tokens.dart';
import 'session_tokens_parser.dart';

abstract interface class TokenRefresher {
  Future<SessionTokens?> refresh({
    required String token,
    required String refreshToken,
  });
}

class ApiTokenRefresher implements TokenRefresher {
  ApiTokenRefresher(this._dio, {this.path = ApiPaths.refresh});

  final Dio _dio;
  final String path;
  final _parser = const SessionTokensParser();

  @override
  Future<SessionTokens?> refresh({
    required String token,
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: {'token': token, 'refreshToken': refreshToken},
      );
      return _parser.fromJson(response.data);
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiError &&
          apiError.type == ApiErrorType.http &&
          (apiError.statusCode == 400 ||
              apiError.statusCode == 401 ||
              apiError.statusCode == 403)) {
        return null;
      }
      rethrow;
    }
  }
}
