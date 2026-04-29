enum AlarmCenterStatus { idle, loading, ready, error }

class AlarmCenterState {
  const AlarmCenterState._({
    required this.status,
    required this.activeCount,
    required this.message,
  });

  const AlarmCenterState.idle()
    : this._(status: AlarmCenterStatus.idle, activeCount: 0, message: null);

  const AlarmCenterState.loading()
    : this._(status: AlarmCenterStatus.loading, activeCount: 0, message: null);

  const AlarmCenterState.ready(int activeCount)
    : this._(
        status: AlarmCenterStatus.ready,
        activeCount: activeCount,
        message: null,
      );

  const AlarmCenterState.error(String message)
    : this._(status: AlarmCenterStatus.error, activeCount: 0, message: message);

  final AlarmCenterStatus status;
  final int activeCount;
  final String? message;
}
