import 'recording.dart';

class RecordingPagedResult {
  const RecordingPagedResult({required this.count, required this.result});

  final int count;
  final List<Recording> result;

  static RecordingPagedResult fromJson(Object? json) {
    if (json is! Map) {
      return const RecordingPagedResult(count: 0, result: []);
    }
    final map = Map<String, dynamic>.from(json);

    int parseCount(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final count = parseCount(map['count'] ?? map['Count']);
    final raw = map['result'] ?? map['Result'];
    final items = <Recording>[];
    if (raw is List) {
      for (final e in raw) {
        try {
          items.add(Recording.fromJson(e));
        } catch (_) {}
      }
    }
    return RecordingPagedResult(count: count, result: items);
  }
}

