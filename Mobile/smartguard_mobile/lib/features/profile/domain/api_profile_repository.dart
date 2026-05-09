import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> getMe() async {
    final response = await _dio.get<Object?>(ApiPaths.me);
    return UserProfile.fromJson(response.data);
  }

  @override
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    final response = await _dio.put<Object?>(
      ApiPaths.updateMe,
      data: request.toJson(),
    );
    return UserProfile.fromJson(response.data);
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _dio.post<Object?>(ApiPaths.changePassword, data: request.toJson());
  }
}
