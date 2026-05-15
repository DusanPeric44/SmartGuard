import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'device.dart';

abstract interface class DevicesRepository {
  Future<List<Device>> fetchDevices();
}

class ApiDevicesRepository implements DevicesRepository {
  ApiDevicesRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Device>> fetchDevices() async {
    final response = await _dio.get<Object?>(ApiPaths.devices);
    final data = response.data;
    if (data is! List) return const <Device>[];
    return data.map(Device.fromJson).toList(growable: false);
  }
}
