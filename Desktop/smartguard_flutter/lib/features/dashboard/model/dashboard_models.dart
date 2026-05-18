import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';

@immutable
class DashboardOverview {
  const DashboardOverview({
    required this.devicesCount,
    required this.connectedDevicesCount,
    required this.recordingsCount,
    required this.pendingAlarmsCount,
    required this.activeUsersCount,
    required this.usedVideosBytes,
    required this.usedImagesBytes,
    required this.usedReportsBytes,
    required this.lastAuditLogs,
  });

  final int devicesCount;
  final int connectedDevicesCount;
  final int recordingsCount;
  final int pendingAlarmsCount;
  final int activeUsersCount;
  final int usedVideosBytes;
  final int usedImagesBytes;
  final int usedReportsBytes;
  final List<AuditLogRow> lastAuditLogs;

  static DashboardOverview fromJson(Object? json) {
    if (json is! Map) {
      throw Exception('Invalid dashboard response');
    }

    final devicesCount =
        _tryInt(json['DevicesCount'] ?? json['devicesCount']) ?? 0;
    final connectedDevicesCount =
        _tryInt(json['ConnectedDevicesCount'] ?? json['connectedDevicesCount']) ??
        0;
    final recordingsCount =
        _tryInt(json['RecordingsCount'] ?? json['recordingsCount']) ?? 0;
    final pendingAlarmsCount =
        _tryInt(json['PendingAlarmsCount'] ?? json['pendingAlarmsCount']) ?? 0;
    final activeUsersCount =
        _tryInt(json['ActiveUsersCount'] ?? json['activeUsersCount']) ?? 0;

    final usedVideosBytes =
        _tryInt(json['UsedVideosBytes'] ?? json['usedVideosBytes']) ?? 0;
    final usedImagesBytes =
        _tryInt(json['UsedImagesBytes'] ?? json['usedImagesBytes']) ?? 0;
    final usedReportsBytes =
        _tryInt(json['UsedReportsBytes'] ?? json['usedReportsBytes']) ?? 0;

    final logs = (json['LastAuditLogs'] ?? json['lastAuditLogs']) as List? ??
        const [];

    return DashboardOverview(
      devicesCount: devicesCount,
      connectedDevicesCount: connectedDevicesCount,
      recordingsCount: recordingsCount,
      pendingAlarmsCount: pendingAlarmsCount,
      activeUsersCount: activeUsersCount,
      usedVideosBytes: usedVideosBytes,
      usedImagesBytes: usedImagesBytes,
      usedReportsBytes: usedReportsBytes,
      lastAuditLogs:
          logs.map((e) => AuditLogRow.fromJson(e)).toList(growable: false),
    );
  }
}

int? _tryInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
