import 'alarm.dart';

class AlarmPagedResult {
  const AlarmPagedResult({required this.result, required this.count});

  final List<Alarm> result;
  final int count;

  static AlarmPagedResult fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('AlarmPagedResult: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final rawResult = map['result'];
    if (rawResult is! List) {
      throw const FormatException('AlarmPagedResult: missing result');
    }

    int parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    final result = rawResult.map((e) => Alarm.fromJson(e)).toList();
    final count = parseInt(map['count']);

    return AlarmPagedResult(
      result: result,
      count: count == 0 ? result.length : count,
    );
  }
}

