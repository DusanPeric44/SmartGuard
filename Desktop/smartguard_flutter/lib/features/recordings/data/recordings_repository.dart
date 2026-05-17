import 'dart:typed_data';

import 'package:smartguard_flutter/features/recordings/model/recording_device_option.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

abstract class RecordingsRepository {
  Future<PageResult<RecordingRow>> list(RecordingsQuery query);
  Future<List<RecordingDeviceOption>> listDevices();
  Future<void> softDelete(int recordingId);
  Future<Uint8List> download(String fileName);
}
