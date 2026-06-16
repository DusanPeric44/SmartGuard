import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/application/devices_state.dart';
import '../../devices/presentation/device_picker.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile_models.dart';
import '../application/live_stream_controller.dart';
import '../application/live_stream_state.dart';
import 'widgets/live_device_selector.dart';
import 'widgets/live_record_button.dart';
import 'widgets/live_status_badge.dart';

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
          LiveDeviceSelector(
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
                    child: LiveStatusBadge(status: state.status),
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
                      child: LiveRecordButton(
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
