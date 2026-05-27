import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';

@immutable
class DeviceRow {
  const DeviceRow({
    required this.id,
    required this.name,

    this.status,
    required this.isActive,
  });

  final String id;
  final String name;
  final DeviceStatus? status;
  final bool isActive;

  factory DeviceRow.fromJson(Map<String, dynamic> json) {
    return DeviceRow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',

      status: json['deviceStatus'] != null
          ? DeviceStatus.fromJson(json['deviceStatus'] as Map<String, dynamic>?)
          : null,
      isActive: json['isActive'] as bool? ?? false,
    );
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

      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
    );
  }
}

@immutable
class DeviceStatus {
  const DeviceStatus(this.id, this.name);

  final int id;
  final String name;

  factory DeviceStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DeviceStatus(0, '');
    }
    return DeviceStatus(
      json['id']?.toInt() ?? 0,
      json['name']?.toString() ?? '',
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
class AssignedUser {
  const AssignedUser({required this.id, required this.username});

  final String id;
  final String username;

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
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
  final List<AssignedUser> assignedUsers;
  final DateTime lastSeenAt;

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    final users = json['assignedUsers'] as List?;
    return DeviceDetails(
      device: DeviceRow.fromJson(json['device'] as Map<String, dynamic>),
      assignedUsers:
          users
              ?.map((u) => AssignedUser.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      lastSeenAt:
          (json['lastSeenAt'] as Object?).toLocalDateTime() ?? DateTime.now(),
    );
  }
}

@immutable
class PagedResult<T> {
  const PagedResult({required this.count, required this.result});

  final int count;
  final List<T> result;
}
