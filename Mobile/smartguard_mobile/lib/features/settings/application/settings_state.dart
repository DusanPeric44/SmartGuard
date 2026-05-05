enum SettingsStatus { idle, loading, ready, error }

class SettingsState {
  const SettingsState._({
    required this.status,
    required this.pushEnabled,
    required this.message,
  });

  const SettingsState.idle()
    : this._(status: SettingsStatus.idle, pushEnabled: false, message: null);

  const SettingsState.loading()
    : this._(status: SettingsStatus.loading, pushEnabled: false, message: null);

  const SettingsState.ready({required bool pushEnabled})
    : this._(
        status: SettingsStatus.ready,
        pushEnabled: pushEnabled,
        message: null,
      );

  const SettingsState.error(String message)
    : this._(
        status: SettingsStatus.error,
        pushEnabled: false,
        message: message,
      );

  final SettingsStatus status;
  final bool pushEnabled;
  final String? message;
}
