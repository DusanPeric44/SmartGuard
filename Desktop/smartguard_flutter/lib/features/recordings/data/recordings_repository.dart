import 'dart:typed_data';

import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

abstract class RecordingsRepository {
  Future<PageResult<RecordingRow>> list(RecordingsQuery query);
  Future<void> softDelete(String recordingId);
  Future<Uint8List> download(String recordingId);
}

