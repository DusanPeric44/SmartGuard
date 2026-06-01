import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';

@immutable
class KnownPersonDetectionImage {
  const KnownPersonDetectionImage({
    required this.id,
    required this.deviceId,
    required this.image,
    required this.timestamp,
    required this.score,
  });

  final int id;
  final int? deviceId;
  final String image;
  final DateTime? timestamp;
  final double? score;

  static KnownPersonDetectionImage fromJson(Object? json) {
    if (json is! Map) {
      throw Exception('Invalid detection image');
    }

    final id = _tryInt(json['id'] ?? json['Id']) ?? 0;
    final deviceId = _tryInt(json['deviceId'] ?? json['DeviceId']);
    final image = (json['image'] ?? json['Image'])?.toString() ?? '';
    final timestamp = DateTime.tryParse(
      (json['timestamp'] ?? json['Timestamp'])?.toString() ?? '',
    )?.toLocalDateTime();
    final score = _tryDouble(json['score'] ?? json['Score']);

    return KnownPersonDetectionImage(
      id: id,
      deviceId: deviceId,
      image: image,
      timestamp: timestamp,
      score: score,
    );
  }
}

int? _tryInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _tryDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
