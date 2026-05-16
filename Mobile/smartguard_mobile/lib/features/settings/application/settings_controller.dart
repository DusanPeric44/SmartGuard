import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_providers.dart';
import '../domain/settings_repository.dart';
import 'settings_state.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SecureSettingsRepository();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState.idle();
  }

  Future<void> load() async {
    state = const SettingsState.loading();
    try {
      final enabled = await ref
          .read(settingsRepositoryProvider)
          .loadPushNotificationsEnabled();
      state = SettingsState.ready(pushEnabled: enabled);
    } catch (_) {
      state = const SettingsState.error('Neuspješno učitavanje postavki');
    }
  }

  Future<void> togglePush(bool enabled) async {
    state = SettingsState.ready(pushEnabled: enabled);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setPushNotificationsEnabled(enabled);
      await ref
          .read(pushNotificationsHandlerProvider)
          .onPushEnabledChanged(enabled);
    } catch (_) {
      state = const SettingsState.error('Neuspješno spremanje postavki');
    }
  }
}
