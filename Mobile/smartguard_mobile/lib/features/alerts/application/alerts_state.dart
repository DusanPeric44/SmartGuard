enum AlertsStatus { idle, loading, ready, error }

class AlertsState {
  const AlertsState._({
    required this.status,
    required this.titles,
    required this.message,
  });

  const AlertsState.idle()
    : this._(status: AlertsStatus.idle, titles: const [], message: null);

  const AlertsState.loading()
    : this._(status: AlertsStatus.loading, titles: const [], message: null);

  const AlertsState.ready(List<String> titles)
    : this._(status: AlertsStatus.ready, titles: titles, message: null);

  const AlertsState.error(String message)
    : this._(status: AlertsStatus.error, titles: const [], message: message);

  final AlertsStatus status;
  final List<String> titles;
  final String? message;
}
