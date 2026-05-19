import 'dashboard_mobile_response.dart';
import 'dashboard_device_list_item.dart';

abstract interface class DashboardRepository {
  Future<DashboardMobileResponse> loadMobileDashboard();
}

class StubDashboardRepository implements DashboardRepository {
  const StubDashboardRepository();

  @override
  Future<DashboardMobileResponse> loadMobileDashboard() async {
    return const DashboardMobileResponse(
      devicesCount: 0,
      pendingAlarmsCount: 0,
      devices: <DashboardDeviceListItem>[],
    );
  }
}
