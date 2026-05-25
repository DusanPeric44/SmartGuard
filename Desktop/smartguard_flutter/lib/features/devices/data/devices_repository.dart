import 'package:smartguard_flutter/features/devices/model/device_models.dart';

abstract class DevicesRepository {
  Future<PagedResult<DeviceRow>> list({
    String? search,
    int? statusId,
    int? page,
    int? pageSize,
  });
  Future<DeviceDetails> getDetails(String deviceId);
  Future<DeviceDetails> assignUsers(String deviceId, List<String> userIds);
  Future<DeviceRow> setActive(String deviceId, bool isActive);
  Future<List<DeviceUser>> listUsers();
  Future<void> provisionDevice({
    required String ssid,
    required String password,
    required String registrationKey,
  });
}
