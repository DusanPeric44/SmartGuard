class LiveStreamFrame {
  const LiveStreamFrame({
    required this.deviceId,
    required this.jpegBase64,
    required this.receivedAt,
  });

  final String deviceId;
  final String jpegBase64;
  final DateTime receivedAt;
}

enum LiveStreamConnectionEventType { connected, reconnecting, disconnected }

class LiveStreamConnectionEvent {
  const LiveStreamConnectionEvent(this.type);

  final LiveStreamConnectionEventType type;
}

class ClipRecordingCompleted {
  const ClipRecordingCompleted({required this.deviceId, required this.clipId});

  final String deviceId;
  final String clipId;
}
