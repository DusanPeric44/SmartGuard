enum NotificationsStatus { idle, loading, ready, error }

class NotificationsState {
  const NotificationsState._({
    required this.status,
    required this.titles,
    required this.message,
  });

  const NotificationsState.idle()
    : this._(status: NotificationsStatus.idle, titles: const [], message: null);

  const NotificationsState.loading()
    : this._(
        status: NotificationsStatus.loading,
        titles: const [],
        message: null,
      );

  const NotificationsState.ready(List<String> titles)
    : this._(status: NotificationsStatus.ready, titles: titles, message: null);

  const NotificationsState.error(String message)
    : this._(
        status: NotificationsStatus.error,
        titles: const [],
        message: message,
      );

  final NotificationsStatus status;
  final List<String> titles;
  final String? message;
}
