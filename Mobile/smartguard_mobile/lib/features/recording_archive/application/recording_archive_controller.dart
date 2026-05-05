import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recording_archive_repository.dart';
import 'recording_archive_state.dart';

final recordingArchiveRepositoryProvider = Provider<RecordingArchiveRepository>(
  (ref) {
    return const StubRecordingArchiveRepository();
  },
);

final recordingArchiveControllerProvider =
    NotifierProvider<RecordingArchiveController, RecordingArchiveState>(
      RecordingArchiveController.new,
    );

class RecordingArchiveController extends Notifier<RecordingArchiveState> {
  @override
  RecordingArchiveState build() {
    return const RecordingArchiveState.idle();
  }

  Future<void> refresh() async {
    state = const RecordingArchiveState.loading();
    try {
      final ids = await ref
          .read(recordingArchiveRepositoryProvider)
          .loadRecentRecordingIds();
      state = RecordingArchiveState.ready(ids);
    } catch (_) {
      state = const RecordingArchiveState.error(
        'Neuspješno učitavanje snimaka',
      );
    }
  }
}
