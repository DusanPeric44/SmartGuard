import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'user_notification_preferences_response.dart';

abstract interface class KnownPersonsRepository {
  Future<UserNotificationPreferencesResponse> search({
    required int page,
    required int pageSize,
  });

  Future<void> setEnabled({required String personId, required bool enabled});
}

class ApiKnownPersonsRepository implements KnownPersonsRepository {
  ApiKnownPersonsRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserNotificationPreferencesResponse> search({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Object?>(
      ApiPaths.knownPersonsPreferencesSearch,
      queryParameters: <String, Object?>{'page': page, 'pageSize': pageSize},
    );
    return UserNotificationPreferencesResponse.fromJson(response.data);
  }

  @override
  Future<void> setEnabled({
    required String personId,
    required bool enabled,
  }) async {
    await _dio.put<Object?>(
      ApiPaths.userNotificationPreferences(personId),
      data: {'enabled': enabled},
    );
  }
}
