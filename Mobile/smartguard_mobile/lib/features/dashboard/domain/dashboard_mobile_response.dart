import 'dashboard_device_list_item.dart';

class DashboardMobileResponse {
  const DashboardMobileResponse({
    required this.devicesCount,
    required this.pendingAlarmsCount,
    required this.devices,
  });

  final int devicesCount;
  final int pendingAlarmsCount;
  final List<DashboardDeviceListItem> devices;

  static DashboardMobileResponse fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException(
        'DashboardMobileResponse: expected object',
      );
    }

    final map = Map<String, dynamic>.from(json);

    Object? pick(List<String> keys) {
      for (final k in keys) {
        if (map.containsKey(k)) return map[k];
      }
      return null;
    }

    int? parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '');
    }

    final devicesCount =
        parseInt(pick(const ['devicesCount', 'DevicesCount']));
    final pendingAlarmsCount =
        parseInt(pick(const ['pendingAlarmsCount', 'PendingAlarmsCount']));
    final devicesRaw = pick(const ['devices', 'Devices']);

    if (devicesCount == null || pendingAlarmsCount == null) {
      throw const FormatException(
        'DashboardMobileResponse: invalid count fields',
      );
    }

    if (devicesRaw is! List) {
      return DashboardMobileResponse(
        devicesCount: devicesCount,
        pendingAlarmsCount: pendingAlarmsCount,
        devices: const <DashboardDeviceListItem>[],
      );
    }

    return DashboardMobileResponse(
      devicesCount: devicesCount,
      pendingAlarmsCount: pendingAlarmsCount,
      devices: devicesRaw
          .map(DashboardDeviceListItem.fromJson)
          .toList(growable: false),
    );
  }
}
