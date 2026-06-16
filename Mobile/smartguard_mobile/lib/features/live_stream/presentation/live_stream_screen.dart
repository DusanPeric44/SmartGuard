import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/application/devices_state.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_picker.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile_models.dart';
import '../application/live_stream_controller.dart';
import '../application/live_stream_state.dart';

class LiveStreamScreen extends ConsumerStatefulWidget {
  const LiveStreamScreen({super.key, this.initialDeviceId});

  final String? initialDeviceId;

  @override
  ConsumerState<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends ConsumerState<LiveStreamScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.initialDeviceId;
      if (id == null || id.isEmpty) return;
      _preselectDevice(id);
    });
  }

  Future<void> _preselectDevice(String deviceId) async {
    final devicesController = ref.read(devicesControllerProvider.notifier);
    var devicesState = ref.read(devicesControllerProvider);
    if (devicesState.selectedDeviceId == deviceId) return;

    if (devicesState.status != DevicesStatus.ready) {
      if (devicesState.status == DevicesStatus.loading) return;
      await devicesController.load();
      if (!mounted) return;
      devicesState = ref.read(devicesControllerProvider);
    }

    if (devicesState.status != DevicesStatus.ready) return;

    for (final device in devicesState.devices) {
      if (device.id == deviceId) {
        devicesController.select(device);
        break;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(liveStreamControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveStreamControllerProvider);
    final controller = ref.read(liveStreamControllerProvider.notifier);
    final devices = ref.watch(devicesControllerProvider);
    final role = ref.watch(profileControllerProvider).profile?.role;

    final selectedDevice = devices.selectedDevice;
    final showRecord =
        role != null && role != UserRole.viewer && state.deviceId != null;

    return SafeArea(
      child: ListView(
        padding: AppDimens.pagePadding,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.liveStreamTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => context.go(AppRoutes.liveFullscreen),
                icon: const Icon(Icons.fullscreen),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceM),
          _DeviceSelector(
            deviceName: selectedDevice?.name,
            status: selectedDevice?.status,
            onTap: () async {
              final device = await showDevicePicker(context);
              if (device == null) return;
              await controller.connect(deviceId: device.id);
            },
          ),
          const SizedBox(height: AppDimens.spaceM),
          AspectRatio(
            aspectRatio: AppDimens.mjpegAspectRatio,
            child: ClipRRect(
              borderRadius: AppDimens.cardRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (state.latestFrameBytes != null)
                    Image.memory(
                      state.latestFrameBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      alignment: Alignment.center,
                      child: Text(
                        state.isConnecting
                            ? AppStrings.liveStreamConnecting
                            : AppStrings.liveStreamNoFrames,
                      ),
                    ),
                  Positioned(
                    left: AppDimens.spaceM,
                    top: AppDimens.spaceM,
                    child: _StatusBadge(status: state.status),
                  ),
                  if (state.status == LiveStreamStatus.error)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(AppDimens.spaceM),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.errorMessage ?? AppStrings.errorUnknown,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.spaceM),
                            FilledButton(
                              onPressed: controller.reconnect,
                              child: const Text(AppStrings.actionRetry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showRecord)
                    Positioned(
                      right: AppDimens.spaceM,
                      bottom: AppDimens.spaceM,
                      child: _RecordButton(
                        isRecording: state.recordingActive,
                        isBusy: state.recordingActionInProgress,
                        onStart: controller.startRecording,
                        onStop: controller.stopRecording,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spaceM),
          Wrap(
            spacing: AppDimens.spaceM,
            runSpacing: AppDimens.spaceM,
            children: [
              Tooltip(
                message: state.deviceId == null
                    ? AppStrings.disabledConnectFirst
                    : '',
                child: OutlinedButton(
                  onPressed: state.deviceId == null
                      ? null
                      : controller.disconnect,
                  child: const Text(AppStrings.actionDisconnect),
                ),
              ),
              FilledButton(
                onPressed: state.deviceId == null
                    ? controller.connectSelectedDevice
                    : controller.reconnect,
                child: Text(
                  state.deviceId == null
                      ? AppStrings.actionConnect
                      : AppStrings.actionReconnect,
                ),
              ),
            ],
          ),
          if (state.lastClipId != null) ...[
            const SizedBox(height: AppDimens.spaceM),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: AppDimens.spaceS),
                Text(AppStrings.liveStreamClipSaved),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final LiveStreamStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      LiveStreamStatus.idle => AppStrings.statusIdle,
      LiveStreamStatus.connecting => AppStrings.statusConnecting,
      LiveStreamStatus.playing => AppStrings.statusPlaying,
      LiveStreamStatus.buffering => AppStrings.statusBuffering,
      LiveStreamStatus.reconnecting => AppStrings.statusReconnecting,
      LiveStreamStatus.error => AppStrings.statusError,
    };

    final color = switch (status) {
      LiveStreamStatus.playing => Colors.green,
      LiveStreamStatus.buffering => Colors.orange,
      LiveStreamStatus.reconnecting => Colors.orange,
      LiveStreamStatus.connecting => Colors.blue,
      LiveStreamStatus.idle => Colors.grey,
      LiveStreamStatus.error => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        border: Border.all(color: color),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.isBusy,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final label = isRecording
        ? AppStrings.liveStreamStop
        : AppStrings.liveStreamRecord;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: isBusy ? null : (isRecording ? onStop : onStart),
          backgroundColor: isRecording ? Colors.red : null,
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
        ),
        const SizedBox(height: AppDimens.spaceS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceM,
            vertical: AppDimens.spaceS,
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
