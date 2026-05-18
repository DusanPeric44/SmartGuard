import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_query.dart';
import 'package:smartguard_flutter/features/audit_logs/model/paged_result.dart';

abstract class AuditLogsRepository {
  Future<PagedResult<AuditLogRow>> list(AuditLogQuery query);
  Future<AuditLogDetails> getById(int id);
}

