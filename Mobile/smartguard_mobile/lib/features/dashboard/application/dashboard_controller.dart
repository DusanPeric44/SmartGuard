import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/api_dashboard_repository.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_state.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return ApiDashboardRepository(ref.read(dioProvider));
});

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState.idle();
  }

  Future<void> refresh() async {
    state = const DashboardState.loading();
    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final response = await repository.loadMobileDashboard();

      state = DashboardState.ready(
        devicesCount: response.devicesCount,
        pendingAlarmsCount: response.pendingAlarmsCount,
        devices: response.devices,
      );
    } catch (_) {
      state = const DashboardState.error(AppStrings.dashboardLoadFailed);
    }
  }
}
