import 'package:smartguard_flutter/features/devices/model/device_models.dart';

abstract class DevicesRepository {
  Future<List<DeviceRow>> list({String? search, DeviceStatus? status});
  Future<DeviceDetails> getDetails(String deviceId);
  Future<DeviceDetails> assignUsers(String deviceId, List<String> userIds);
  Future<DeviceRow> setActive(String deviceId, bool isActive);
  Future<List<DeviceUser>> listUsers();
}

