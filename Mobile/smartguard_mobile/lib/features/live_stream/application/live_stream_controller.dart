import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/api_error.dart';
import '../../devices/application/devices_controller.dart';
import '../domain/live_stream_models.dart';
import '../domain/live_stream_repository.dart';
import 'live_stream_state.dart';

Uint8List _decodeBase64Jpeg(String input) {
  return base64Decode(input);
}

final liveStreamRepositoryProvider = Provider<LiveStreamRepository>((ref) {
  final session = ref.read(sessionControllerProvider.notifier);
  final repo = SignalRLiveStreamRepository(session: session);
  ref.onDispose(() {
    unawaited(repo.dispose());
  });
  return repo;
});

final liveStreamControllerProvider =
    NotifierProvider<LiveStreamController, LiveStreamState>(
      LiveStreamController.new,
    );

class LiveStreamController extends Notifier<LiveStreamState> {
  final _errorMapper = const UiErrorMapper();

  StreamSubscription<LiveStreamFrame>? _frameSub;
  StreamSubscription<LiveStreamConnectionEvent>? _eventSub;
  StreamSubscription<ClipRecordingCompleted>? _clipSub;

  Timer? _frameGapTimer;
  Timer? _recordingTimer;
  Timer? _uiThrottleTimer;

  String? _pendingBase64;
  bool _decoding = false;

  Uint8List? _pendingBytes;
  DateTime? _lastUiEmitAt;

  bool _resumeAfterPause = false;

  @override
  LiveStreamState build() {
    ref.onDispose(_disposeInternal);
    return const LiveStreamState.initial();
  }

  Future<void> connectSelectedDevice() async {
    final devices = ref.read(devicesControllerProvider);
    final selected = devices.selectedDevice;
    if (selected == null) {
      state = state.copyWith(
        status: LiveStreamStatus.error,
        errorMessage: AppStrings.liveStreamSelectDevice,
      );
      return;
    }

    await connect(deviceId: selected.id);
  }

  Future<void> connect({required String deviceId}) async {
    await _cancelStreamSubscriptions();

    state = state.copyWith(
      deviceId: deviceId,
      status: LiveStreamStatus.connecting,
      errorMessage: null,
      latestFrameBytes: null,
      lastFrameAt: null,
    );

    final repo = ref.read(liveStreamRepositoryProvider);

    _eventSub = repo.connectionEvents().listen(_onConnectionEvent);
    _frameSub = repo.frames().listen(
      _onRawFrame,
      onError: (e) {
        state = state.copyWith(
          status: LiveStreamStatus.error,
          errorMessage: _mapMessage(e),
        );
      },
    );
    _clipSub = repo.recordingCompleted().listen(_onClipCompleted);

    try {
      await repo.start(deviceId: deviceId);
    } catch (e) {
      state = state.copyWith(
        status: LiveStreamStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> disconnect() async {
    _resumeAfterPause = false;
    await _cancelStreamSubscriptions();
    try {
      await ref.read(liveStreamRepositoryProvider).stop();
    } catch (_) {}

    state = state.copyWith(
      status: LiveStreamStatus.idle,
      latestFrameBytes: null,
      lastFrameAt: null,
      errorMessage: null,
      recordingStatus: RecordingStatus.idle,
      recordingElapsed: Duration.zero,
      lastClipId: null,
      uploadProgress: null,
    );
  }

  Future<void> reconnect() async {
    final deviceId = state.deviceId;
    if (deviceId == null) return;
    await connect(deviceId: deviceId);
  }

  void onAppPaused() {
    _resumeAfterPause =
        state.deviceId != null &&
        state.status != LiveStreamStatus.idle &&
        state.status != LiveStreamStatus.error;
    unawaited(disconnect());
  }

  void onAppResumed() {
    if (!_resumeAfterPause) return;
    _resumeAfterPause = false;
    unawaited(reconnect());
  }

  Future<void> startRecording() async {
    final deviceId = state.deviceId;
    if (deviceId == null) return;
    if (state.recordingStatus == RecordingStatus.recording) return;

    state = state.copyWith(
      recordingStatus: RecordingStatus.starting,
      recordingElapsed: Duration.zero,
      errorMessage: null,
      lastClipId: null,
    );

    try {
      await ref
          .read(liveStreamRepositoryProvider)
          .startRecording(deviceId: deviceId);
      state = state.copyWith(recordingStatus: RecordingStatus.recording);
      _startRecordingTimer();
    } catch (e) {
      state = state.copyWith(
        recordingStatus: RecordingStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> stopRecording() async {
    final deviceId = state.deviceId;
    if (deviceId == null) return;
    if (state.recordingStatus != RecordingStatus.recording) return;

    _stopRecordingTimer();
    state = state.copyWith(recordingStatus: RecordingStatus.stopping);

    try {
      await ref
          .read(liveStreamRepositoryProvider)
          .stopRecording(deviceId: deviceId);
      state = state.copyWith(recordingStatus: RecordingStatus.uploading);
    } catch (e) {
      state = state.copyWith(
        recordingStatus: RecordingStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  void _onConnectionEvent(LiveStreamConnectionEvent event) {
    final next = switch (event.type) {
      LiveStreamConnectionEventType.connected =>
        state.latestFrameBytes == null
            ? LiveStreamStatus.connecting
            : LiveStreamStatus.playing,
      LiveStreamConnectionEventType.reconnecting =>
        LiveStreamStatus.reconnecting,
      LiveStreamConnectionEventType.disconnected => LiveStreamStatus.error,
    };

    state = state.copyWith(
      status: next,
      errorMessage: next == LiveStreamStatus.error
          ? AppStrings.errorNetwork
          : null,
    );
  }

  void _onRawFrame(LiveStreamFrame frame) {
    _resetFrameGapTimer();
    _enqueueDecode(frame.jpegBase64);
  }

  void _enqueueDecode(String base64) {
    _pendingBase64 = base64;
    if (_decoding) return;
    _decoding = true;
    unawaited(_drainDecodeQueue());
  }

  Future<void> _drainDecodeQueue() async {
    while (true) {
      final base64 = _pendingBase64;
      _pendingBase64 = null;
      if (base64 == null) break;

      try {
        final bytes = await compute(_decodeBase64Jpeg, base64);
        _emitFrame(bytes);
      } catch (e) {
        state = state.copyWith(
          status: LiveStreamStatus.error,
          errorMessage: _mapMessage(e),
        );
      }
    }
    _decoding = false;
  }

  void _emitFrame(Uint8List bytes) {
    final now = DateTime.now();
    final last = _lastUiEmitAt;
    if (last == null || now.difference(last) >= AppDurations.uiFrameThrottle) {
      _lastUiEmitAt = now;
      _uiThrottleTimer?.cancel();
      state = state.copyWith(
        status: LiveStreamStatus.playing,
        latestFrameBytes: bytes,
        lastFrameAt: now,
        errorMessage: null,
      );
      return;
    }

    _pendingBytes = bytes;
    _uiThrottleTimer ??= Timer(
      AppDurations.uiFrameThrottle - now.difference(last),
      () {
        _uiThrottleTimer = null;
        final pending = _pendingBytes;
        _pendingBytes = null;
        if (pending == null) return;
        _emitFrame(pending);
      },
    );
  }

  void _resetFrameGapTimer() {
    _frameGapTimer?.cancel();
    _frameGapTimer = Timer(AppDurations.frameGapThreshold, () {
      if (state.status == LiveStreamStatus.playing) {
        state = state.copyWith(status: LiveStreamStatus.buffering);
      }
    });
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(AppDurations.oneSecond, (_) {
      final next = state.recordingElapsed + AppDurations.oneSecond;
      state = state.copyWith(recordingElapsed: next);
      if (next >= AppDurations.recordingMaxDuration) {
        unawaited(stopRecording());
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _onClipCompleted(ClipRecordingCompleted clip) {
    state = state.copyWith(
      recordingStatus: RecordingStatus.success,
      lastClipId: clip.clipId,
      uploadProgress: null,
    );
  }

  Future<void> _cancelStreamSubscriptions() async {
    _frameGapTimer?.cancel();
    _frameGapTimer = null;
    _uiThrottleTimer?.cancel();
    _uiThrottleTimer = null;
    await _frameSub?.cancel();
    await _eventSub?.cancel();
    await _clipSub?.cancel();
    _frameSub = null;
    _eventSub = null;
    _clipSub = null;
  }

  void _disposeInternal() {
    _frameGapTimer?.cancel();
    _recordingTimer?.cancel();
    _uiThrottleTimer?.cancel();
    unawaited(_cancelStreamSubscriptions());
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
