import 'package:flutter/foundation.dart';

enum DeviceStatus { online, offline, maintenance }

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

  factory DeviceRow.fromJson(Map<String, dynamic> json) {
    return DeviceRow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
      status: _parseStatus(json['status']),
      storageTotalGb: json['storageTotalGb'] as int? ?? 0,
      storageUsedGb: json['storageUsedGb'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  static DeviceStatus _parseStatus(dynamic value) {
    if (value is int) {
      return DeviceStatus.values.elementAtOrNull(value) ?? DeviceStatus.offline;
    }
    final s = value?.toString().toLowerCase();
    switch (s) {
      case 'online':
      case '0':
        return DeviceStatus.online;
      case 'offline':
      case '1':
        return DeviceStatus.offline;
      case 'maintenance':
      case '2':
        return DeviceStatus.maintenance;
      default:
        return DeviceStatus.offline;
    }
  }

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
  const DeviceUser({required this.id, required this.email});

  final String id;
  final String email;

  factory DeviceUser.fromJson(Map<String, dynamic> json) {
    return DeviceUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
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

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    final users = json['assignedUsers'] as List?;
    return DeviceDetails(
      device: DeviceRow.fromJson(json['device'] as Map<String, dynamic>),
      assignedUsers:
          users
              ?.map((u) => DeviceUser.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      lastSeenAt:
          DateTime.tryParse(json['lastSeenAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class PagedResult<T> {
  const PagedResult({required this.count, required this.result});

  final int count;
  final List<T> result;
}
