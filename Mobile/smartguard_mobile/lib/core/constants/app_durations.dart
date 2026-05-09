class AppDurations {
  const AppDurations._();

  static const Duration reconnectMinDelay = Duration(milliseconds: 500);
  static const Duration reconnectStep1 = Duration(seconds: 2);
  static const Duration reconnectStep2 = Duration(seconds: 5);
  static const Duration reconnectMaxDelay = Duration(seconds: 10);
  static const Duration frameGapThreshold = Duration(milliseconds: 800);
  static const Duration uiFrameThrottle = Duration(milliseconds: 66);
  static const Duration oneSecond = Duration(seconds: 1);
  static const Duration recordingMaxDuration = Duration(seconds: 15);
}
