import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/live_stream_repository.dart';
import 'live_stream_state.dart';

final liveStreamRepositoryProvider = Provider<LiveStreamRepository>((ref) {
  return const StubLiveStreamRepository();
});

final liveStreamControllerProvider =
    NotifierProvider<LiveStreamController, LiveStreamState>(
      LiveStreamController.new,
    );

class LiveStreamController extends Notifier<LiveStreamState> {
  @override
  LiveStreamState build() {
    return const LiveStreamState.idle();
  }

  Future<void> connect() async {
    state = const LiveStreamState.connecting();
    try {
      await ref.read(liveStreamRepositoryProvider).connect();
      state = const LiveStreamState.connected();
    } catch (_) {
      state = const LiveStreamState.error('Neuspješno povezivanje');
    }
  }

  Future<void> disconnect() async {
    try {
      await ref.read(liveStreamRepositoryProvider).disconnect();
    } finally {
      state = const LiveStreamState.idle();
    }
  }
}
