abstract interface class RecordingArchiveRepository {
  Future<List<String>> loadRecentRecordingIds();
}

class StubRecordingArchiveRepository implements RecordingArchiveRepository {
  const StubRecordingArchiveRepository();

  @override
  Future<List<String>> loadRecentRecordingIds() async {
    return const [];
  }
}
