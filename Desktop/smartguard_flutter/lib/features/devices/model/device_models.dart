import 'package:flutter/foundation.dart';

enum DeviceStatus {
  online,
  offline,
  maintenance,
}

@immutable
class DeviceRow {
  const DeviceRow({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.status,
    required this.storageTotalGb,
    required this.storageUsedGb,
    required this.isActive,
  });

  final String id;
  final String name;
  final String ipAddress;
  final DeviceStatus status;
  final int storageTotalGb;
  final int storageUsedGb;
  final bool isActive;

  DeviceRow copyWith({
    String? id,
    String? name,
    String? ipAddress,
    DeviceStatus? status,
    int? storageTotalGb,
    int? storageUsedGb,
    bool? isActive,
  }) {
    return DeviceRow(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      status: status ?? this.status,
      storageTotalGb: storageTotalGb ?? this.storageTotalGb,
      storageUsedGb: storageUsedGb ?? this.storageUsedGb,
      isActive: isActive ?? this.isActive,
    );
  }
}

@immutable
class DeviceUser {
  const DeviceUser({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;
}

@immutable
class DeviceDetails {
  const DeviceDetails({
    required this.device,
    required this.assignedUsers,
    required this.lastSeenAt,
  });

  final DeviceRow device;
  final List<DeviceUser> assignedUsers;
  final DateTime lastSeenAt;
}

