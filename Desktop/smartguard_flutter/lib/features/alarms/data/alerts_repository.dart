import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_status.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_type.dart';
import 'package:smartguard_flutter/features/alarms/model/alerts_query.dart';
import 'package:smartguard_flutter/features/alarms/model/paged_result.dart';

abstract class AlertsRepository {
  Future<PagedResult<AlertRow>> list(AlertsQuery query);
  Future<List<AlertStatus>> listStatuses();
  Future<List<AlertType>> listTypes();
  Future<AlertRow> confirm(int id);
  Future<AlertRow> resolve(int id);
  Future<AlertRow> dismiss(int id, {required String dismissalReason});
}
