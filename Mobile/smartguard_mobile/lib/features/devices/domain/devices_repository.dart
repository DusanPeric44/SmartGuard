import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'devices_response.dart';

abstract interface class DevicesRepository {
  Future<DevicesResponse> fetchDevices();
}

class ApiDevicesRepository implements DevicesRepository {
  ApiDevicesRepository(this._dio);

  final Dio _dio;

  @override
  Future<DevicesResponse> fetchDevices() async {
    final response = await _dio.get<Object?>(ApiPaths.devices);
    return DevicesResponse.fromJson(response.data);
  }
}
