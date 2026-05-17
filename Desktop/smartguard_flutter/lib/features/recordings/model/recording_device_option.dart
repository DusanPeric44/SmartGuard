import 'package:flutter/foundation.dart';

@immutable
class RecordingDeviceOption {
  const RecordingDeviceOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

