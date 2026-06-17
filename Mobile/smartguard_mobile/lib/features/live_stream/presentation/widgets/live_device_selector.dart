import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../devices/domain/device.dart';

class LiveDeviceSelector extends StatelessWidget {
  const LiveDeviceSelector({
    super.key,
    required this.deviceName,
    required this.status,
    required this.onTap,
  });

  final String? deviceName;
  final DeviceStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DeviceStatus.online => Colors.green,
      DeviceStatus.streaming => Colors.blue,
      DeviceStatus.offline => Colors.grey,
      DeviceStatus.unknown || null => Colors.orange,
    };

    return InkWell(
      borderRadius: AppDimens.cardRadius,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppDimens.cardRadius,
        ),
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimens.spaceM),
            Expanded(
              child: Text(
                deviceName ?? AppStrings.liveStreamSelectDevice,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
