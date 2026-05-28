import 'package:flutter/foundation.dart';

@immutable
class AlertsQuery {
  const AlertsQuery({this.statusName, this.page = 1, this.pageSize = 25});

  final String? statusName;
  final int page;
  final int pageSize;

  AlertsQuery copyWith({String? statusName, int? page, int? pageSize}) {
    return AlertsQuery(
      statusName: statusName ?? this.statusName,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
