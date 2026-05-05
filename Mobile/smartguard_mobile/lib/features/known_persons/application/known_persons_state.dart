enum KnownPersonsStatus { idle, loading, ready, error }

class KnownPersonsState {
  const KnownPersonsState._({
    required this.status,
    required this.names,
    required this.message,
  });

  const KnownPersonsState.idle()
    : this._(status: KnownPersonsStatus.idle, names: const [], message: null);

  const KnownPersonsState.loading()
    : this._(
        status: KnownPersonsStatus.loading,
        names: const [],
        message: null,
      );

  const KnownPersonsState.ready(List<String> names)
    : this._(status: KnownPersonsStatus.ready, names: names, message: null);

  const KnownPersonsState.error(String message)
    : this._(
        status: KnownPersonsStatus.error,
        names: const [],
        message: message,
      );

  final KnownPersonsStatus status;
  final List<String> names;
  final String? message;
}
