enum RecordingArchiveStatus { idle, loading, ready, error }

class RecordingArchiveState {
  const RecordingArchiveState._({
    required this.status,
    required this.recordingIds,
    required this.message,
  });

  const RecordingArchiveState.idle()
    : this._(
        status: RecordingArchiveStatus.idle,
        recordingIds: const [],
        message: null,
      );

  const RecordingArchiveState.loading()
    : this._(
        status: RecordingArchiveStatus.loading,
        recordingIds: const [],
        message: null,
      );

  const RecordingArchiveState.ready(List<String> recordingIds)
    : this._(
        status: RecordingArchiveStatus.ready,
        recordingIds: recordingIds,
        message: null,
      );

  const RecordingArchiveState.error(String message)
    : this._(
        status: RecordingArchiveStatus.error,
        recordingIds: const [],
        message: message,
      );

  final RecordingArchiveStatus status;
  final List<String> recordingIds;
  final String? message;
}
