import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';

@immutable
class AuditLogRow {
  const AuditLogRow({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.action,
    required this.resource,
    required this.details,
    required this.status,
    required this.ipAddress,
  });

  final int id;
  final DateTime? timestamp;
  final String user;
  final String action;
  final String resource;
  final String details;
  final String status;
  final String ipAddress;

  static AuditLogRow fromJson(Object? json) {
    if (json is! Map) {
      throw Exception('Invalid AuditLog row');
    }

    final id = _tryInt(
          json['id'] ??
              json['auditLogId'] ??
              json['auditLogID'] ??
              json['Id'] ??
              json['ID'],
        ) ??
        0;

    final timestamp = _tryDateTime(
      json['timestamp'] ??
          json['Timestamp'] ??
          json['createdAt'] ??
          json['CreatedAt'] ??
          json['date'] ??
          json['Date'],
    );

    final user =
        _tryString(json['user'] ?? json['User'] ?? json['userId'] ?? json['UserId'] ?? json['username'] ?? json['Username']) ??
        '';

    final action = _tryString(json['action'] ?? json['Action']) ?? '';
    final resource = _tryString(json['resource'] ?? json['Resource']) ?? '';
    final status = _tryString(json['status'] ?? json['Status']) ?? '';
    final details =
        _tryString(json['details'] ?? json['Details'] ?? json['message'] ?? json['Message'] ?? json['text'] ?? json['Text']) ??
        '';

    final ipAddress =
        _tryString(json['ipAddress'] ?? json['IpAddress'] ?? json['ip'] ?? json['Ip'] ?? json['remoteIpAddress'] ?? json['RemoteIpAddress']) ??
        '';

    return AuditLogRow(
      id: id,
      timestamp: timestamp,
      user: user,
      action: action,
      resource: resource,
      details: details,
      status: status,
      ipAddress: ipAddress,
    );
  }
}

@immutable
class AuditLogDetails {
  const AuditLogDetails({required this.id, required this.raw});

  final int id;
  final Map<String, Object?> raw;

  static AuditLogDetails fromJson(Object? json) {
    if (json is! Map) {
      throw Exception('Invalid AuditLog details');
    }
    final map = Map<String, Object?>.from(json);
    final id =
        _tryInt(map['id'] ?? map['auditLogId'] ?? map['Id'] ?? map['ID']) ?? 0;
    return AuditLogDetails(id: id, raw: map);
  }
}

int? _tryInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String? _tryString(Object? v) {
  final s = v?.toString();
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

DateTime? _tryDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
  }
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      v.toInt(),
      isUtc: true,
    ).toLocal();
  }
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return s.toLocalDateTime();
}
