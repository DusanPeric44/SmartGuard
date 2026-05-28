import '../constants/app_durations.dart';

class SignalRConstants {
  const SignalRConstants._();

  static const String streamHubPath = '/hubs/stream';
  static const String notificationsHubPath = '/hub/notifications';

  static const List<Duration> reconnectDelays = <Duration>[
    AppDurations.reconnectMinDelay,
    AppDurations.reconnectStep1,
    AppDurations.reconnectStep2,
    AppDurations.reconnectMaxDelay,
  ];
}
