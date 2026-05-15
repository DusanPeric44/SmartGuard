import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../application/devices_controller.dart';
import '../application/devices_state.dart';
import '../domain/device.dart';

Future<Device?> showDevicePicker(BuildContext context) {
  return showModalBottomSheet<Device?>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return const _DevicePickerSheet();
    },
  );
}

class _DevicePickerSheet extends ConsumerWidget {
  const _DevicePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(devicesControllerProvider);
    final controller = ref.read(devicesControllerProvider.notifier);

    if (state.status == DevicesStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.load();
      });
    }

    return SafeArea(
      child: Padding(
        padding: AppDimens.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.liveStreamSelectDevice,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.spaceM),
            if (state.status == DevicesStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                child: CircularProgressIndicator(),
              )
            else if (state.status == DevicesStatus.error)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                child: Text(state.errorMessage ?? AppStrings.errorUnknown),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = state.devices[index];
                    return ListTile(
                      leading: _StatusDot(status: device.status),
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      trailing: device.id == state.selectedDeviceId
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        controller.select(device);
                        Navigator.of(context).pop(device);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

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
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

