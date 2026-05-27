import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';

enum RecordingType { motion, manual, alarm }

enum RecordingStatus { available, processing, failed, deleted }

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
    final typeId = (json['recordingTypeId'] as num?)?.toInt();
    final statusId = (json['recordingStatusId'] as num?)?.toInt();
    final Object? startedRaw =
        json['timestamp'] ?? json['startedAt'] ?? json['start'] ?? json['time'];
    return RecordingRow(
      id: (json['id'] as num?)?.toInt() ?? int.parse(json['id'].toString()),
      deviceId:
          (json['deviceId'] as num?)?.toInt() ??
          int.parse(json['deviceId'].toString()),
      deviceName: json['deviceName']?.toString() ?? '',
      startedAt:
          startedRaw.toLocalDateTime() ?? DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      type: _parseType(typeId),
      status: _parseStatus(statusId),
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

  static RecordingStatus _parseStatus(int? id) {
    if (id == null) return RecordingStatus.available;
    final idx = id - 1;
    if (idx < 0 || idx >= RecordingStatus.values.length) {
      return RecordingStatus.available;
    }
    return RecordingStatus.values[idx];
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
