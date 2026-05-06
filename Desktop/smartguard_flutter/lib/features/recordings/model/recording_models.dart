import 'package:flutter/foundation.dart';

enum RecordingType {
  motion,
  manual,
  alarm,
}

enum RecordingStatus {
  available,
  processing,
  failed,
  deleted,
}

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
    this.deletedAt,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final DateTime startedAt;
  final int durationSeconds;
  final int sizeBytes;
  final RecordingType type;
  final RecordingStatus status;
  final DateTime? deletedAt;
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
    this.sortBy = RecordingsSortBy.startedAt,
    this.sortDir = SortDir.desc,
    this.page = 1,
    this.pageSize = 25,
  });

  final String? deviceId;
  final RecordingType? type;
  final RecordingStatus? status;
  final String? search;
  final DateTime? from;
  final DateTime? to;
  final RecordingsSortBy sortBy;
  final SortDir sortDir;
  final int page;
  final int pageSize;

  RecordingsQuery copyWith({
    String? deviceId,
    RecordingType? type,
    RecordingStatus? status,
    String? search,
    DateTime? from,
    DateTime? to,
    RecordingsSortBy? sortBy,
    SortDir? sortDir,
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
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

enum RecordingsSortBy {
  startedAt,
  deviceName,
  status,
  sizeBytes,
  durationSeconds,
}

enum SortDir { asc, desc }

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

