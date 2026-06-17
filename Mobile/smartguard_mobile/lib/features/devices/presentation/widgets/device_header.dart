import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/device.dart';
import 'device_status_dot.dart';

class DeviceHeader extends StatelessWidget {
  const DeviceHeader({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (AppStrings.deviceDetailStatusLabel, deviceStatusLabel(device.status)),
      if (device.location.trim().isNotEmpty)
        (AppStrings.deviceDetailLocationLabel, device.location.trim()),
      if ((device.lastSeenIso?.trim().isNotEmpty ?? false))
        (AppStrings.deviceDetailLastSeenLabel, device.lastSeenIso!.trim()),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DeviceStatusDot(status: device.status),
                const SizedBox(width: AppDimens.spaceM),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceM),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
