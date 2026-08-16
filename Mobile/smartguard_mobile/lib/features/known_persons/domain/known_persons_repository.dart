import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'user_notification_preferences_response.dart';

abstract interface class KnownPersonsRepository {
  Future<UserNotificationPreferencesResponse> search({
    required int page,
    required int pageSize,
  });

  Future<void> setEnabled({required String personId, required bool enabled});

  /// Uploads a photo (raw file bytes) and returns the URL to use as [create]'s pictureUrl.
  Future<String> uploadImage({
    required List<int> bytes,
    required String fileName,
  });

  Future<void> create({
    required String firstName,
    required String lastName,
    String? pictureUrl,
  });

  Future<void> delete(String personId);
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

  @override
  Future<String> uploadImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post<Object?>(
      ApiPaths.filesUploadImage,
      data: form,
    );
    final data = response.data;
    if (data is Map && data['url'] is String) {
      return data['url'] as String;
    }
    throw const FormatException('Upload response missing url');
  }

  @override
  Future<void> create({
    required String firstName,
    required String lastName,
    String? pictureUrl,
  }) async {
    await _dio.post<Object?>(
      ApiPaths.knownPersons,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        if (pictureUrl != null) 'picture': pictureUrl,
      },
    );
  }

  @override
  Future<void> delete(String personId) async {
    await _dio.delete<Object?>(ApiPaths.knownPersonById(personId));
  }
}
