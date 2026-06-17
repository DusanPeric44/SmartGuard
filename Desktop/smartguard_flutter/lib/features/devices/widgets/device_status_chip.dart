import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class DeviceStatusChip extends StatelessWidget {
  const DeviceStatusChip({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status.name;
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label),
    );
  }
}

Color _statusColor(BuildContext context, DeviceStatus status) {
  switch (status.name) {
    case 'Online':
      return Colors.greenAccent.shade400;
    case 'Offline':
      return Colors.blueGrey.shade300;
    case 'Maintenance':
      return Colors.amberAccent.shade400;
    default:
      return Colors.grey;
  }
}
