import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../alarm_center/application/alarm_center_controller.dart';
import '../../alarm_center/application/alarm_center_state.dart';
import '../../recording_archive/application/recording_archive_controller.dart';
import '../../recording_archive/application/recording_archive_state.dart';
import '../application/devices_controller.dart';
import '../application/devices_state.dart';
import '../domain/device.dart';
import 'widgets/device_alarm_row.dart';
import 'widgets/device_empty_hint.dart';
import 'widgets/device_header.dart';
import 'widgets/device_recording_row.dart';

/// Master-detail screen: a single device (master) shown together with its
/// related alarms and recordings (details), reached from the dashboard.
class DeviceDetailScreen extends ConsumerStatefulWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  static const int _maxChildren = 5;

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureData());
  }

  void _ensureData() {
    final devices = ref.read(devicesControllerProvider);
    if (devices.status == DevicesStatus.idle ||
        (devices.status == DevicesStatus.ready && devices.devices.isEmpty)) {
      ref.read(devicesControllerProvider.notifier).load();
    }

    final alarms = ref.read(alarmCenterControllerProvider);
    if (alarms.status == AlarmCenterStatus.idle) {
      ref.read(alarmCenterControllerProvider.notifier).loadInitial();
    }

    final recordings = ref.read(recordingArchiveControllerProvider);
    if (recordings.status == RecordingArchiveStatus.idle) {
      ref.read(recordingArchiveControllerProvider.notifier).loadInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesControllerProvider);
    final device = _findDevice(devices.devices);

    final title = device?.name ?? AppStrings.deviceDetailTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: _buildBody(context, devices, device)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DevicesState devices,
    Device? device,
  ) {
    if (device == null) {
      if (devices.status == DevicesStatus.loading ||
          devices.status == DevicesStatus.idle) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(child: Text(AppStrings.deviceDetailNotFound));
    }

    final alarms = ref.watch(alarmCenterControllerProvider);
    final recordings = ref.watch(recordingArchiveControllerProvider);

    final deviceAlarms = alarms.items
        .where((a) => _matchesDevice(a.title, device))
        .take(DeviceDetailScreen._maxChildren)
        .toList();
    final deviceRecordings = recordings.items
        .where(
          (r) =>
              _matchesDevice(r.deviceName, device) ||
              _matchesDevice(r.deviceLocation, device),
        )
        .take(DeviceDetailScreen._maxChildren)
        .toList();

    return ListView(
      padding: AppDimens.pagePadding,
      children: [
        DeviceHeader(device: device),
        const SizedBox(height: AppDimens.spaceM),
        FilledButton.icon(
          onPressed: () => context.push(
            Uri(
              path: AppRoutes.live,
              queryParameters: <String, String>{'deviceId': device.id},
            ).toString(),
          ),
          icon: const Icon(Icons.videocam_outlined),
          label: const Text(AppStrings.deviceDetailOpenLive),
        ),
        const SizedBox(height: AppDimens.spaceL),
        Text(
          AppStrings.deviceDetailAlarmsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimens.spaceM),
        if (deviceAlarms.isEmpty)
          DeviceEmptyHint(message: AppStrings.deviceDetailNoAlarms)
        else
          for (final alarm in deviceAlarms)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
              child: DeviceAlarmRow(alarm: alarm),
            ),
        const SizedBox(height: AppDimens.spaceL),
        Text(
          AppStrings.deviceDetailRecordingsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimens.spaceM),
        if (deviceRecordings.isEmpty)
          DeviceEmptyHint(message: AppStrings.deviceDetailNoRecordings)
        else
          for (final recording in deviceRecordings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
              child: DeviceRecordingRow(recording: recording),
            ),
      ],
    );
  }

  Device? _findDevice(List<Device> devices) {
    for (final d in devices) {
      if (d.id == widget.deviceId) return d;
    }
    return null;
  }

  static bool _matchesDevice(String value, Device device) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return false;
    final name = device.name.trim().toLowerCase();
    final location = device.location.trim().toLowerCase();
    return (name.isNotEmpty && v == name) ||
        (location.isNotEmpty && v == location);
  }
}
