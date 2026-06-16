import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../alarm_center/application/alarm_center_controller.dart';
import '../../alarm_center/application/alarm_center_state.dart';
import '../../alarm_center/domain/alarm.dart';
import '../../recording_archive/application/recording_archive_controller.dart';
import '../../recording_archive/application/recording_archive_state.dart';
import '../../recording_archive/domain/recording.dart';
import '../application/devices_controller.dart';
import '../application/devices_state.dart';
import '../domain/device.dart';

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
        _DeviceHeader(device: device),
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
          _EmptyHint(message: AppStrings.deviceDetailNoAlarms)
        else
          for (final alarm in deviceAlarms)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
              child: _AlarmRow(alarm: alarm),
            ),
        const SizedBox(height: AppDimens.spaceL),
        Text(
          AppStrings.deviceDetailRecordingsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimens.spaceM),
        if (deviceRecordings.isEmpty)
          _EmptyHint(message: AppStrings.deviceDetailNoRecordings)
        else
          for (final recording in deviceRecordings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spaceS),
              child: _RecordingRow(recording: recording),
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

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (AppStrings.deviceDetailStatusLabel, _statusLabel(device.status)),
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
                _StatusDot(status: device.status),
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

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (alarm.uiStatus) {
      AlarmUiStatus.pending => Icons.warning_amber_rounded,
      AlarmUiStatus.confirmed => Icons.report_rounded,
      AlarmUiStatus.resolved => Icons.check_circle_rounded,
      AlarmUiStatus.unknown => Icons.notifications_outlined,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: ListTile(
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(alarm.title.trim().isEmpty ? 'Alarm' : alarm.title),
        subtitle: alarm.message.trim().isEmpty ? null : Text(alarm.message),
      ),
    );
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: ListTile(
        leading: const Icon(Icons.movie_outlined),
        title: Text(
          recording.title.trim().isEmpty ? 'Recording' : recording.title,
        ),
        subtitle: Text(
          recording.typeName.trim().isEmpty
              ? recording.durationLabel
              : '${recording.typeName.trim()} · ${recording.durationLabel}',
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceS),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _statusLabel(DeviceStatus status) {
  return switch (status) {
    DeviceStatus.online => AppStrings.deviceStatusOnline,
    DeviceStatus.streaming => AppStrings.deviceStatusStreaming,
    DeviceStatus.offline => AppStrings.deviceStatusOffline,
    DeviceStatus.unknown => AppStrings.deviceStatusUnknown,
  };
}
