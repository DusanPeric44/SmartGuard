import 'package:dio/dio.dart';

import '../constants/api_paths.dart';

abstract interface class PushTokenRepository {
  Future<void> registerToken({required String token, required String platform});
}

class ApiPushTokenRepository implements PushTokenRepository {
  ApiPushTokenRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post<Object?>(
      ApiPaths.pushToken,
      data: {'token': token, 'platform': platform},
    );
  }
}
