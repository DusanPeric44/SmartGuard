import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'recording_paged_result.dart';

abstract interface class RecordingArchiveRepository {
  Future<RecordingPagedResult> search({required int page, required int pageSize});
}

class ApiRecordingArchiveRepository implements RecordingArchiveRepository {
  ApiRecordingArchiveRepository(this._dio);

  final Dio _dio;

  @override
  Future<RecordingPagedResult> search({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Object?>(
      ApiPaths.recordings,
      queryParameters: {'Page': page, 'PageSize': pageSize},
    );
    return RecordingPagedResult.fromJson(response.data);
  }
}
