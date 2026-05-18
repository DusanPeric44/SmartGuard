import 'package:flutter/foundation.dart';

@immutable
class AlertsQuery {
  const AlertsQuery({this.statusId, this.page = 1, this.pageSize = 25});

  final int? statusId;
  final int page;
  final int pageSize;

  AlertsQuery copyWith({int? statusId, int? page, int? pageSize}) {
    return AlertsQuery(
      statusId: statusId ?? this.statusId,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
