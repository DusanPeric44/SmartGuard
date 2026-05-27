import 'dart:async';

import '../../../core/auth/session_controller.dart';
import '../../../core/realtime/signalr_client.dart';
import '../live_stream_constants.dart';
import 'live_stream_models.dart';

abstract interface class LiveStreamRepository {
  Future<void> start({required String deviceId});
  Future<void> stop();

  Stream<LiveStreamFrame> frames();
  Stream<LiveStreamConnectionEvent> connectionEvents();
  Stream<ClipRecordingCompleted> recordingCompleted();
  Stream<LiveStreamRecordingEvent> recordingEvents();

  Future<void> startRecording({required String deviceId});
  Future<void> stopRecording({required String deviceId});
}

class SignalRLiveStreamRepository implements LiveStreamRepository {
  SignalRLiveStreamRepository({required SessionController session})
    : _client = SignalRClient.build(
        hubPath: LiveStreamHub.hubPath,
        accessTokenProvider: () async => session.tokens?.accessToken,
      );

  final SignalRClient _client;

  final _frames = StreamController<LiveStreamFrame>.broadcast();
  final _events = StreamController<LiveStreamConnectionEvent>.broadcast();
  final _recordingCompleted =
      StreamController<ClipRecordingCompleted>.broadcast();
  final _recordingEvents =
      StreamController<LiveStreamRecordingEvent>.broadcast();

  String? _activeDeviceId;

  @override
  Stream<LiveStreamFrame> frames() => _frames.stream;

  @override
  Stream<LiveStreamConnectionEvent> connectionEvents() => _events.stream;

  @override
  Stream<ClipRecordingCompleted> recordingCompleted() =>
      _recordingCompleted.stream;

  @override
  Stream<LiveStreamRecordingEvent> recordingEvents() => _recordingEvents.stream;

  @override
  Future<void> start({required String deviceId}) async {
    _activeDeviceId = deviceId;
    _wireHandlersIfNeeded();
    await _client.start();
    await _client.invoke(
      LiveStreamHub.methodStartStream,
      args: <Object>[deviceId],
    );
  }

  @override
  Future<void> stop() async {
    final deviceId = _activeDeviceId;
    _activeDeviceId = null;
    if (deviceId != null) {
      await _client.invoke(
        LiveStreamHub.methodStopStream,
        args: <Object>[deviceId],
      );
    }
    await _client.stop();
  }

  @override
  Future<void> startRecording({required String deviceId}) {
    return _client.invoke(
      LiveStreamHub.methodStartRecording,
      args: <Object>[deviceId],
    );
  }

  @override
  Future<void> stopRecording({required String deviceId}) {
    return _client.invoke(
      LiveStreamHub.methodStopRecording,
      args: <Object>[deviceId],
    );
  }

  bool _wired = false;
  void _wireHandlersIfNeeded() {
    if (_wired) return;
    _wired = true;

    _client.statusStream.listen((status) {
      final event = switch (status) {
        SignalRConnectionStatus.connected => const LiveStreamConnectionEvent(
          LiveStreamConnectionEventType.connected,
        ),
        SignalRConnectionStatus.reconnecting => const LiveStreamConnectionEvent(
          LiveStreamConnectionEventType.reconnecting,
        ),
        SignalRConnectionStatus.disconnected => const LiveStreamConnectionEvent(
          LiveStreamConnectionEventType.disconnected,
        ),
        SignalRConnectionStatus.connecting => const LiveStreamConnectionEvent(
          LiveStreamConnectionEventType.reconnecting,
        ),
      };
      _events.add(event);
    });

    _client.on(LiveStreamHub.eventFrame, (args) {
      final parsed = _parseFrame(args);
      if (parsed == null) return;
      if (_activeDeviceId != null && parsed.deviceId != _activeDeviceId) return;
      _frames.add(parsed);
    });

    _client.on(LiveStreamHub.eventRecordingCompleted, (args) {
      final deviceId = _activeDeviceId;
      final clip = _parseClip(args);
      if (clip == null) return;
      if (deviceId != null && clip.deviceId != deviceId) return;
      _recordingCompleted.add(clip);
    });

    _client.on(LiveStreamHub.eventRecordingStarted, (args) {
      final deviceId = _parseDeviceId(args);
      if (deviceId == null) return;
      _recordingEvents.add(
        LiveStreamRecordingEvent(
          type: LiveStreamRecordingEventType.started,
          deviceId: deviceId,
        ),
      );
    });

    _client.on(LiveStreamHub.eventRecordingStopped, (args) {
      final deviceId = _parseDeviceId(args);
      if (deviceId == null) return;
      _recordingEvents.add(
        LiveStreamRecordingEvent(
          type: LiveStreamRecordingEventType.stopped,
          deviceId: deviceId,
        ),
      );
    });
  }

  LiveStreamFrame? _parseFrame(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;

    if (args.length >= 2 && args[0] is String && args[1] is String) {
      return LiveStreamFrame(
        deviceId: args[0] as String,
        jpegBase64: args[1] as String,
        receivedAt: DateTime.now(),
      );
    }

    final first = args.first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      final deviceId = map[LiveStreamHub.keyDeviceId]?.toString();
      final jpegBase64 = map[LiveStreamHub.keyJpegBase64]?.toString();
      if (deviceId == null || jpegBase64 == null) return null;
      return LiveStreamFrame(
        deviceId: deviceId,
        jpegBase64: jpegBase64,
        receivedAt: DateTime.now(),
      );
    }

    return null;
  }

  ClipRecordingCompleted? _parseClip(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;

    if (args.length >= 2 && args[0] is String && args[1] is String) {
      return ClipRecordingCompleted(
        deviceId: args[0] as String,
        clipId: args[1] as String,
      );
    }

    final first = args.first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      final deviceId = map[LiveStreamHub.keyDeviceId]?.toString();
      final clipId = map[LiveStreamHub.keyClipId]?.toString();
      if (deviceId == null || clipId == null) return null;
      return ClipRecordingCompleted(deviceId: deviceId, clipId: clipId);
    }

    return null;
  }

  String? _parseDeviceId(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final first = args.first;
    if (first is String) return first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      return map[LiveStreamHub.keyDeviceId]?.toString();
    }
    return null;
  }

  Future<void> dispose() async {
    await _client.dispose();
    await _frames.close();
    await _events.close();
    await _recordingCompleted.close();
    await _recordingEvents.close();
  }
}
