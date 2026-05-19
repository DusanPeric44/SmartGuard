import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'alarm.dart';
import 'alarm_dismiss_request.dart';
import 'alarm_paged_result.dart';

abstract interface class AlarmCenterRepository {
  Future<AlarmPagedResult> search({required int page, required int pageSize});
  Future<Alarm> confirm({required int id});
  Future<Alarm> dismiss({required int id, required AlarmDismissRequest request});
}

class ApiAlarmCenterRepository implements AlarmCenterRepository {
  ApiAlarmCenterRepository(this._dio);

  final Dio _dio;

  @override
  Future<AlarmPagedResult> search({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Object?>(
      ApiPaths.alerts,
      queryParameters: {'Page': page, 'PageSize': pageSize},
    );
    return AlarmPagedResult.fromJson(response.data);
  }

  @override
  Future<Alarm> confirm({required int id}) async {
    final response = await _dio.post<Object?>(ApiPaths.alertConfirm(id));
    return Alarm.fromJson(response.data);
  }

  @override
  Future<Alarm> dismiss({
    required int id,
    required AlarmDismissRequest request,
  }) async {
    final response = await _dio.post<Object?>(
      ApiPaths.alertDismiss(id),
      data: request.toJson(),
    );
    return Alarm.fromJson(response.data);
  }
}
