import 'package:http/http.dart' as http;
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class ApiDevicesRepository implements DevicesRepository {
  ApiDevicesRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<DeviceRow>> list({
    String? search,
    DeviceStatus? status,
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParameters['name'] = search;
    }
    if (status != null) {
      queryParameters['statusId'] = status.index.toString();
    }
    if (page != null) {
      queryParameters['page'] = page.toString();
    }
    if (pageSize != null) {
      queryParameters['pageSize'] = pageSize.toString();
    }

    final path = Uri(
      path: '/devices/my',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<DeviceRow>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? [];
          return PagedResult<DeviceRow>(
            count: count,
            result: items
                .map((i) => DeviceRow.fromJson(i as Map<String, dynamic>))
                .toList(),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<DeviceDetails> getDetails(String deviceId) async {
    return _api.get<DeviceDetails>(
      '/devices/details/$deviceId',
      decode: (json) => DeviceDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<DeviceDetails> assignUsers(
    String deviceId,
    List<String> userIds,
  ) async {
    return _api.post<DeviceDetails>(
      '/devices/$deviceId/users',
      body: userIds,
      decode: (json) => DeviceDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<DeviceRow> setActive(String deviceId, bool isActive) async {
    return _api.post<DeviceRow>(
      '/devices/$deviceId/active',
      body: {'isActive': isActive},
      decode: (json) => DeviceRow.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<List<DeviceUser>> listUsers() async {
    return _api.get<List<DeviceUser>>(
      '/users',
      decode: (json) {
        if (json is List) {
          return json
              .map((i) => DeviceUser.fromJson(i as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<void> provisionDevice({
    required String ssid,
    required String password,
    required String registrationKey,
  }) async {
    final response = await http
        .post(
          Uri.parse('http://192.168.4.1/provision'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'ssid': ssid, 'password': password, 'apiKey': registrationKey},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Uređaj je vratio grešku: ${response.statusCode}');
    }
  }
}
