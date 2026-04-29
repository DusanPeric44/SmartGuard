import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notifications_repository.dart';
import 'notifications_state.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return const StubNotificationsRepository();
});

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    return const NotificationsState.idle();
  }

  Future<void> refresh() async {
    state = const NotificationsState.loading();
    try {
      final titles = await ref
          .read(notificationsRepositoryProvider)
          .loadLatestNotificationTitles();
      state = NotificationsState.ready(titles);
    } catch (_) {
      state = const NotificationsState.error(
        'Neuspješno učitavanje notifikacija',
      );
    }
  }
}
