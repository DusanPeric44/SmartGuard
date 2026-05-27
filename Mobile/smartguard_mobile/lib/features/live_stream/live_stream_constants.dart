class LiveStreamHub {
  const LiveStreamHub._();

  static const String hubPath = '/hub/camera';

  static const String methodStartStream = 'StartStream';
  static const String methodStopStream = 'StopStream';

  static const String methodStartRecording = 'StartRecording';
  static const String methodStopRecording = 'StopRecording';

  static const String eventFrame = 'MjpegFrame';
  static const String eventStatus = 'DeviceStreamStatus';
  static const String eventRecordingCompleted = 'RecordingCompleted';
  static const String eventRecordingStarted = 'StartRecording';
  static const String eventRecordingStopped = 'StopRecording';

  static const String keyDeviceId = 'deviceId';
  static const String keyJpegBase64 = 'jpegBase64';
  static const String keyClipId = 'clipId';
}
