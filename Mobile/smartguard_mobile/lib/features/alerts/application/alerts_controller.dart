import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alerts_repository.dart';
import 'alerts_state.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return const StubAlertsRepository();
});

final alertsControllerProvider =
    NotifierProvider<AlertsController, AlertsState>(AlertsController.new);

class AlertsController extends Notifier<AlertsState> {
  @override
  AlertsState build() {
    return const AlertsState.idle();
  }

  Future<void> refresh() async {
    state = const AlertsState.loading();
    try {
      final titles = await ref
          .read(alertsRepositoryProvider)
          .loadActiveAlertTitles();
      state = AlertsState.ready(titles);
    } catch (_) {
      state = const AlertsState.error('Neuspješno učitavanje alert-a');
    }
  }
}
