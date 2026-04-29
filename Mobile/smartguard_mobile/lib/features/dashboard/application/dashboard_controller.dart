import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/futures.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_state.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const StubDashboardRepository();
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
      final results = await waitAll<int>([
        repository.loadUnreadNotificationsCount(),
        repository.loadActiveCamerasCount(),
        repository.loadNewAlarmsCount(),
      ]);

      state = DashboardState.ready(
        unreadNotifications: results[0],
        activeCameras: results[1],
        newAlarms: results[2],
      );
    } catch (_) {
      state = const DashboardState.error('Neuspješno učitavanje dashboard-a');
    }
  }
}
