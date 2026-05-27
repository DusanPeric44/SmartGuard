enum DeviceStatus { unknown, online, offline, streaming }

class DeviceStatusInfo {
  const DeviceStatusInfo({required this.id, required this.name});

  final String id;
  final String name;

  static DeviceStatusInfo fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('DeviceStatusInfo: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final id = (map['id'] ?? map['deviceStatusId'] ?? '').toString();
    final name = (map['name'] ?? map['status'] ?? '').toString();
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw const FormatException('DeviceStatusInfo: missing fields');
    }
    return DeviceStatusInfo(id: id, name: name);
  }
}

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.apiKey,
    this.deviceStatus,
    this.lastSeenIso,
  });

  final String id;
  final String name;
  final DeviceStatus status;
  final String location;
  final String apiKey;
  final DeviceStatusInfo? deviceStatus;
  final String? lastSeenIso;

  static Device fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Device: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final id = (map['id'] ?? map['deviceId'] ?? '').toString();
    final name = (map['name'] ?? map['displayName'] ?? id).toString();
    final statusRaw = (map['status'] ?? '').toString().toLowerCase();

    DeviceStatusInfo? deviceStatus;
    final deviceStatusRaw = map['deviceStatus'];
    if (deviceStatusRaw != null) {
      try {
        deviceStatus = DeviceStatusInfo.fromJson(deviceStatusRaw);
      } catch (_) {}
    }

    final deviceStatusName =
        deviceStatus?.name.toLowerCase() ??
        (map['deviceStatusName'] ?? '').toString().toLowerCase();

    final status = switch (statusRaw.isNotEmpty
        ? statusRaw
        : deviceStatusName) {
      'online' => DeviceStatus.online,
      'offline' => DeviceStatus.offline,
      'streaming' => DeviceStatus.streaming,
      _ => DeviceStatus.unknown,
    };

    int parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    if (id.trim().isEmpty) {
      throw const FormatException('Device: missing id');
    }

    return Device(
      id: id,
      name: name,
      status: status,
      location: (map['location'] ?? '').toString(),
      apiKey: (map['apiKey'] ?? map['api_key'] ?? '').toString(),
      deviceStatus: deviceStatus,
      lastSeenIso: map['lastSeen']?.toString(),
    );
  }
}
