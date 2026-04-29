import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alarm_center_repository.dart';
import 'alarm_center_state.dart';

final alarmCenterRepositoryProvider = Provider<AlarmCenterRepository>((ref) {
  return const StubAlarmCenterRepository();
});

final alarmCenterControllerProvider =
    NotifierProvider<AlarmCenterController, AlarmCenterState>(
      AlarmCenterController.new,
    );

class AlarmCenterController extends Notifier<AlarmCenterState> {
  @override
  AlarmCenterState build() {
    return const AlarmCenterState.idle();
  }

  Future<void> refresh() async {
    state = const AlarmCenterState.loading();
    try {
      final count = await ref
          .read(alarmCenterRepositoryProvider)
          .loadActiveAlarmCount();
      state = AlarmCenterState.ready(count);
    } catch (_) {
      state = const AlarmCenterState.error('Neuspješno učitavanje alarma');
    }
  }
}
