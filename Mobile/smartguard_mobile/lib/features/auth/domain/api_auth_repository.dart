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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      ApiPaths.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
    return AuthTokens.fromJson(response.data);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _dio.post<Object?>(
      ApiPaths.forgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<Object?>(
      ApiPaths.resetPassword,
      data: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }
}
