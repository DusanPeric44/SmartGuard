class AlarmDismissRequest {
  const AlarmDismissRequest({required this.dismissalReason});

  final String dismissalReason;

  Map<String, dynamic> toJson() => {'dismissalReason': dismissalReason};
}

