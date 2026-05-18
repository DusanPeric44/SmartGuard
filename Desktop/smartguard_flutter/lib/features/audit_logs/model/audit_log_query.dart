import 'package:flutter/foundation.dart';

@immutable
class AuditLogQuery {
  const AuditLogQuery({
    this.userId,
    this.action,
    this.resource,
    this.status,
    this.text,
    this.from,
    this.to,
    this.page = 1,
    this.pageSize = 25,
  });

  final String? userId;
  final String? action;
  final String? resource;
  final String? status;
  final String? text;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int pageSize;

  AuditLogQuery copyWith({
    String? userId,
    String? action,
    String? resource,
    String? status,
    String? text,
    DateTime? from,
    DateTime? to,
    int? page,
    int? pageSize,
  }) {
    return AuditLogQuery(
      userId: userId ?? this.userId,
      action: action ?? this.action,
      resource: resource ?? this.resource,
      status: status ?? this.status,
      text: text ?? this.text,
      from: from ?? this.from,
      to: to ?? this.to,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

