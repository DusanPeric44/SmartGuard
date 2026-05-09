import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(response.data);
  }

  @override
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      ApiPaths.register,
      data: {'fullName': fullName, 'email': email, 'password': password},
    );
    return AuthTokens.fromJson(response.data);
  }
}
