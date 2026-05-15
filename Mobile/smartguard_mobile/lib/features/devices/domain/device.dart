enum DeviceStatus { unknown, online, offline, streaming }

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.status,
    this.lastSeenIso,
  });

  final String id;
  final String name;
  final DeviceStatus status;
  final String? lastSeenIso;

  static Device fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Device: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final id = (map['id'] ?? map['deviceId'] ?? '').toString();
    final name = (map['name'] ?? map['displayName'] ?? id).toString();
    final statusRaw = (map['status'] ?? '').toString().toLowerCase();

    final status = switch (statusRaw) {
      'online' => DeviceStatus.online,
      'offline' => DeviceStatus.offline,
      'streaming' => DeviceStatus.streaming,
      _ => DeviceStatus.unknown,
    };

    if (id.trim().isEmpty) {
      throw const FormatException('Device: missing id');
    }

    return Device(
      id: id,
      name: name,
      status: status,
      lastSeenIso: map['lastSeen']?.toString(),
    );
  }
}
