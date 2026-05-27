import 'package:flutter/foundation.dart';

enum LiveStreamStatus {
  idle,
  connecting,
  playing,
  buffering,
  reconnecting,
  error,
}

@immutable
class LiveStreamState {
  const LiveStreamState({
    required this.deviceId,
    required this.status,
    required this.recordingActive,
    required this.recordingActionInProgress,
    required this.latestFrameBytes,
    required this.lastFrameAt,
    required this.lastClipId,
    required this.errorMessage,
  });

  const LiveStreamState.initial()
    : deviceId = null,
      status = LiveStreamStatus.idle,
      recordingActive = false,
      recordingActionInProgress = false,
      latestFrameBytes = null,
      lastFrameAt = null,
      lastClipId = null,
      errorMessage = null;

  final String? deviceId;
  final LiveStreamStatus status;
  final bool recordingActive;
  final bool recordingActionInProgress;

  final Uint8List? latestFrameBytes;
  final DateTime? lastFrameAt;

  final String? lastClipId;

  final String? errorMessage;

  bool get isConnecting =>
      status == LiveStreamStatus.connecting ||
      status == LiveStreamStatus.reconnecting;

  bool get isRecording => recordingActive;

  LiveStreamState copyWith({
    String? deviceId,
    LiveStreamStatus? status,
    bool? recordingActive,
    bool? recordingActionInProgress,
    Uint8List? latestFrameBytes,
    DateTime? lastFrameAt,
    String? lastClipId,
    String? errorMessage,
  }) {
    return LiveStreamState(
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      recordingActive: recordingActive ?? this.recordingActive,
      recordingActionInProgress:
          recordingActionInProgress ?? this.recordingActionInProgress,
      latestFrameBytes: latestFrameBytes ?? this.latestFrameBytes,
      lastFrameAt: lastFrameAt ?? this.lastFrameAt,
      lastClipId: lastClipId ?? this.lastClipId,
      errorMessage: errorMessage,
    );
  }
}
