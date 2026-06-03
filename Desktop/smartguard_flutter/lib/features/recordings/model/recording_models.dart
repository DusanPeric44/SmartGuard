import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';

enum RecordingType { motion, faceDetected, manual }

enum RecordingStatus { pending, uploading, completed, failed, archived }

@immutable
class RecordingRow {
  const RecordingRow({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.type,
    required this.status,
    this.fileName = '',
    required this.filePath,
    this.deletedAt,
  });

  final int id;
  final int deviceId;
  final String deviceName;
  final DateTime startedAt;
  final int durationSeconds;
  final int sizeBytes;
  final RecordingType type;
  final RecordingStatus status;
  final String fileName;
  final String filePath;
  final DateTime? deletedAt;

  factory RecordingRow.fromJson(Map<String, dynamic> json) {
    final typeId = (json['typeId'] as Object?);
    final Object? startedRaw =
        json['timestamp'] ?? json['startedAt'] ?? json['start'] ?? json['time'];
    final device = json['device'];
    final deviceName =
        (device is Map ? device['name']?.toString() : null) ??
        json['deviceName']?.toString() ??
        '';
    return RecordingRow(
      id: (json['id'] as num?)?.toInt() ?? int.parse(json['id'].toString()),
      deviceId:
          (json['deviceId'] as num?)?.toInt() ??
          int.parse(json['deviceId'].toString()),
      deviceName: deviceName,
      startedAt:
          startedRaw.toLocalDateTime() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds:
          ((json['durationSeconds'] ?? json['duration']) as num?)?.toInt() ?? 0,
      sizeBytes: ((json['sizeBytes'] ?? json['size']) as num?)?.toInt() ?? 0,
      type: _parseType((typeId as num?)?.toInt()),
      status: _parseStatus((json["recordingStatus"] as Map<String, dynamic>)),
      fileName: _extractFileName(json['filePath']?.toString() ?? ''),
      filePath: json['filePath']?.toString() ?? '',
      deletedAt: (json['deletedAt'] as Object?).toLocalDateTime(),
    );
  }

  static RecordingType _parseType(int? id) {
    if (id == null) return RecordingType.motion;
    final idx = id - 1;
    if (idx < 0 || idx >= RecordingType.values.length) {
      return RecordingType.motion;
    }
    return RecordingType.values[idx];
  }

  static RecordingStatus _parseStatus(Map<String, dynamic> status) {
    final statusName = status['name']?.toString().toLowerCase() ?? '';
    if (statusName.isEmpty) return RecordingStatus.failed;
    return RecordingStatus.values.firstWhere(
      (element) => element.name == statusName,
      orElse: () => RecordingStatus.failed,
    );
  }

  static String _extractFileName(String s) => s.split('/').last;
}

@immutable
class RecordingsQuery {
  const RecordingsQuery({
    this.deviceId,
    this.type,
    this.status,
    this.search,
    this.from,
    this.to,
    this.page = 1,
    this.pageSize = 25,
  });

  final int? deviceId;
  final RecordingType? type;
  final RecordingStatus? status;
  final String? search;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int pageSize;

  RecordingsQuery copyWith({
    int? deviceId,
    RecordingType? type,
    RecordingStatus? status,
    String? search,
    DateTime? from,
    DateTime? to,
    int? page,
    int? pageSize,
  }) {
    return RecordingsQuery(
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      status: status ?? this.status,
      search: search ?? this.search,
      from: from ?? this.from,
      to: to ?? this.to,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

@immutable
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
}
