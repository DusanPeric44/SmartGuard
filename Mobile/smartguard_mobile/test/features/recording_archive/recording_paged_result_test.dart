import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/features/recording_archive/domain/recording_paged_result.dart';

void main() {
  test('parses paged result', () {
    final raw = <String, Object?>{
      'count': 2,
      'result': [
        {
          'id': 1,
          'duration': 10,
          'timestamp': '2026-05-18T19:34:14.8741984Z',
          'recordingType': {'id': 1, 'name': 'Motion'},
          'device': {'id': 1, 'name': 'Cam-1', 'location': 'Front Door'},
        },
        {
          'id': 2,
          'duration': 20,
          'timestamp': '2026-05-18T20:34:14.8741984Z',
          'recordingType': {'id': 2, 'name': 'Face Event'},
          'device': {'id': 1, 'name': 'Cam-1', 'location': 'Backyard'},
        },
      ],
    };

    final parsed = RecordingPagedResult.fromJson(raw);
    expect(parsed.count, 2);
    expect(parsed.result.length, 2);
    expect(parsed.result.first.id, 1);
    expect(parsed.result.last.typeName, 'Face Event');
  });

  test('handles null result list', () {
    final raw = <String, Object?>{'count': 0, 'result': null};
    final parsed = RecordingPagedResult.fromJson(raw);
    expect(parsed.count, 0);
    expect(parsed.result, isEmpty);
  });
}

