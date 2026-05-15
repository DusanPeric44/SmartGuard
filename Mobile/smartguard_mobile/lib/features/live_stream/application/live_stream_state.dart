import 'package:flutter/foundation.dart';

enum LiveStreamStatus {
  idle,
  connecting,
  playing,
  buffering,
  reconnecting,
  error,
}

enum RecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  uploading,
  success,
  error,
}

@immutable
class LiveStreamState {
  const LiveStreamState({
    required this.deviceId,
    required this.status,
    required this.recordingStatus,
    required this.latestFrameBytes,
    required this.lastFrameAt,
    required this.recordingElapsed,
    required this.lastClipId,
    required this.uploadProgress,
    required this.errorMessage,
  });

  const LiveStreamState.initial()
    : deviceId = null,
      status = LiveStreamStatus.idle,
      recordingStatus = RecordingStatus.idle,
      latestFrameBytes = null,
      lastFrameAt = null,
      recordingElapsed = Duration.zero,
      lastClipId = null,
      uploadProgress = null,
      errorMessage = null;

  final String? deviceId;
  final LiveStreamStatus status;
  final RecordingStatus recordingStatus;

  final Uint8List? latestFrameBytes;
  final DateTime? lastFrameAt;

  final Duration recordingElapsed;
  final String? lastClipId;
  final double? uploadProgress;

  final String? errorMessage;

  bool get isConnecting =>
      status == LiveStreamStatus.connecting ||
      status == LiveStreamStatus.reconnecting;

  bool get isRecording => recordingStatus == RecordingStatus.recording;

  LiveStreamState copyWith({
    String? deviceId,
    LiveStreamStatus? status,
    RecordingStatus? recordingStatus,
    Uint8List? latestFrameBytes,
    DateTime? lastFrameAt,
    Duration? recordingElapsed,
    String? lastClipId,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return LiveStreamState(
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      recordingStatus: recordingStatus ?? this.recordingStatus,
      latestFrameBytes: latestFrameBytes ?? this.latestFrameBytes,
      lastFrameAt: lastFrameAt ?? this.lastFrameAt,
      recordingElapsed: recordingElapsed ?? this.recordingElapsed,
      lastClipId: lastClipId ?? this.lastClipId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
    );
  }
}
