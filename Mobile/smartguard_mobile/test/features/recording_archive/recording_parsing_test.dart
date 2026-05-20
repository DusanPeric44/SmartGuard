import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/features/recording_archive/domain/recording.dart';

void main() {
  test('parses recording from swagger-like json', () {
    final raw = <String, Object?>{
      'id': 7,
      'filePath': '/videos/archive/clip-7.mp4?sig=abc',
      'duration': 75,
      'timestamp': '2026-05-18T19:34:14.8741984Z',
      'recordingType': {'id': 1, 'name': 'Motion'},
      'device': {'id': 1, 'name': 'Cam-1', 'location': 'Backyard'},
    };

    final rec = Recording.fromJson(raw);
    expect(rec.id, 7);
    expect(rec.fileName, 'clip-7.mp4');
    expect(rec.durationSeconds, 75);
    expect(rec.durationLabel, '1:15');
    expect(rec.title, 'Backyard');
    expect(rec.typeName, 'Motion');
    expect(rec.timestamp.toUtc().year, 2026);
  });
}

