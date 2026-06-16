import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/device.dart';

class DeviceStatusDot extends StatelessWidget {
  const DeviceStatusDot({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DeviceStatus.online => Colors.green,
      DeviceStatus.streaming => Colors.blue,
      DeviceStatus.offline => Colors.grey,
      DeviceStatus.unknown => Colors.orange,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String deviceStatusLabel(DeviceStatus status) {
  return switch (status) {
    DeviceStatus.online => AppStrings.deviceStatusOnline,
    DeviceStatus.streaming => AppStrings.deviceStatusStreaming,
    DeviceStatus.offline => AppStrings.deviceStatusOffline,
    DeviceStatus.unknown => AppStrings.deviceStatusUnknown,
  };
}
