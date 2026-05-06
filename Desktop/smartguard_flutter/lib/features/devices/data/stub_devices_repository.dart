import 'dart:math';

import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class StubDevicesRepository implements DevicesRepository {
  StubDevicesRepository({int seed = 11}) : _rng = Random(seed) {
    _users = const [
      DeviceUser(id: 'u1', username: 'admin01'),
      DeviceUser(id: 'u2', username: 'home01'),
      DeviceUser(id: 'u3', username: 'viewer01'),
      DeviceUser(id: 'u4', username: 'viewer02'),
    ];

    _devices = List.generate(28, (i) {
      final statusRoll = _rng.nextDouble();
      final status = statusRoll < 0.7
          ? DeviceStatus.online
          : (statusRoll < 0.9 ? DeviceStatus.offline : DeviceStatus.maintenance);
      final total = 256 + _rng.nextInt(1024);
      final used = 20 + _rng.nextInt(total - 10);
      return DeviceRow(
        id: 'camera-${(i + 1).toString().padLeft(2, '0')}',
        name: 'Camera ${(i + 1).toString().padLeft(2, '0')}',
        ipAddress: '192.168.1.${10 + i}',
        status: status,
        storageTotalGb: total,
        storageUsedGb: used,
        isActive: _rng.nextDouble() > 0.05,
      );
    });

    _assignments = <String, Set<String>>{
      for (final d in _devices)
        d.id: <String>{
          if (_rng.nextBool()) 'u2',
          if (_rng.nextDouble() > 0.6) 'u3',
        },
    };
  }

  final Random _rng;
  late final List<DeviceRow> _devices;
  late final List<DeviceUser> _users;
  late final Map<String, Set<String>> _assignments;

  @override
  Future<List<DeviceRow>> list({String? search, DeviceStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    Iterable<DeviceRow> items = _devices;
    if (status != null) {
      items = items.where((d) => d.status == status);
    }
    final q = (search ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.id.toLowerCase().contains(q) ||
            d.ipAddress.toLowerCase().contains(q);
      });
    }
    return items.toList(growable: false);
  }

  @override
  Future<DeviceDetails> getDetails(String deviceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final device = _devices.firstWhere((d) => d.id == deviceId);
    final assigned = _assignments[deviceId] ?? <String>{};
    final users = _users.where((u) => assigned.contains(u.id)).toList(growable: false);
    return DeviceDetails(
      device: device,
      assignedUsers: users,
      lastSeenAt: DateTime.now().subtract(Duration(minutes: _rng.nextInt(240))),
    );
  }

  @override
  Future<DeviceDetails> assignUsers(String deviceId, List<String> userIds) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _assignments[deviceId] = userIds.toSet();
    return getDetails(deviceId);
  }

  @override
  Future<DeviceRow> setActive(String deviceId, bool isActive) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx < 0) throw StateError('Device not found');
    final updated = _devices[idx].copyWith(isActive: isActive);
    _devices[idx] = updated;
    return updated;
  }

  @override
  Future<List<DeviceUser>> listUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<DeviceUser>.from(_users);
  }
}

