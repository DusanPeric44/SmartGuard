enum LiveStreamStatus { idle, connecting, connected, error }

class LiveStreamState {
  const LiveStreamState._({required this.status, required this.message});

  const LiveStreamState.idle()
    : this._(status: LiveStreamStatus.idle, message: null);

  const LiveStreamState.connecting()
    : this._(status: LiveStreamStatus.connecting, message: null);

  const LiveStreamState.connected()
    : this._(status: LiveStreamStatus.connected, message: null);

  const LiveStreamState.error(String message)
    : this._(status: LiveStreamStatus.error, message: message);

  final LiveStreamStatus status;
  final String? message;
}
