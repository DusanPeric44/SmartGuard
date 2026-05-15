import 'device.dart';

class DevicesResponse {
  const DevicesResponse({required this.result, required this.count});

  final List<Device> result;
  final int count;

  static DevicesResponse fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('DevicesResponse: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final rawResult = map['result'];
    if (rawResult is! List) {
      throw const FormatException('DevicesResponse: missing result');
    }

    int parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    final devices = rawResult.map(Device.fromJson).toList(growable: false);
    final count = parseInt(map['count']);

    return DevicesResponse(
      result: devices,
      count: count == 0 ? devices.length : count,
    );
  }
}

