import '../domain/dashboard_device_list_item.dart';

enum DashboardStatus { idle, loading, ready, error }

class DashboardState {
  const DashboardState._({
    required this.status,
    required this.devicesCount,
    required this.pendingAlarmsCount,
    required this.devices,
    required this.message,
  });

  const DashboardState.idle()
    : this._(
        status: DashboardStatus.idle,
        devicesCount: 0,
        pendingAlarmsCount: 0,
        devices: const <DashboardDeviceListItem>[],
        message: null,
      );

  const DashboardState.loading()
    : this._(
        status: DashboardStatus.loading,
        devicesCount: 0,
        pendingAlarmsCount: 0,
        devices: const <DashboardDeviceListItem>[],
        message: null,
      );

  const DashboardState.ready({
    required int devicesCount,
    required int pendingAlarmsCount,
    required List<DashboardDeviceListItem> devices,
  }) : this._(
         status: DashboardStatus.ready,
         devicesCount: devicesCount,
         pendingAlarmsCount: pendingAlarmsCount,
         devices: devices,
         message: null,
       );

  const DashboardState.error(String message)
    : this._(
        status: DashboardStatus.error,
        devicesCount: 0,
        pendingAlarmsCount: 0,
        devices: const <DashboardDeviceListItem>[],
        message: message,
      );

  final DashboardStatus status;
  final int devicesCount;
  final int pendingAlarmsCount;
  final List<DashboardDeviceListItem> devices;
  final String? message;
}
