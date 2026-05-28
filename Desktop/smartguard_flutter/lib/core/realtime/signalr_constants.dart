class SignalRConstants {
  const SignalRConstants._();

  static const String notificationsHubPath = '/hub/notifications';

  static const List<Duration> reconnectDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];
}

