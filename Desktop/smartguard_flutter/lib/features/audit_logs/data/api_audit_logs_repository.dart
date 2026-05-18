import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/audit_logs/data/audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_query.dart';
import 'package:smartguard_flutter/features/audit_logs/model/paged_result.dart';

class ApiAuditLogsRepository implements AuditLogsRepository {
  ApiAuditLogsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<AuditLogRow>> list(AuditLogQuery query) async {
    final queryParameters = <String, String>{
      'Page': query.page.toString(),
      'PageSize': query.pageSize.toString(),
    };

    final userId = query.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      queryParameters['UserId'] = userId;
    }

    final action = query.action?.trim();
    if (action != null && action.isNotEmpty) {
      queryParameters['Action'] = action;
    }

    final resource = query.resource?.trim();
    if (resource != null && resource.isNotEmpty) {
      queryParameters['Resource'] = resource;
    }

    final status = query.status?.trim();
    if (status != null && status.isNotEmpty) {
      queryParameters['Status'] = status;
    }

    final text = query.text?.trim();
    if (text != null && text.isNotEmpty) {
      queryParameters['Text'] = text;
    }

    if (query.from != null) {
      queryParameters['From'] = query.from!.toIso8601String();
    }
    if (query.to != null) {
      queryParameters['To'] = query.to!.toIso8601String();
    }

    final path = Uri(
      path: '/AuditLogs',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<AuditLogRow>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<AuditLogRow>(
            count: count,
            result: items
                .map((i) => AuditLogRow.fromJson(i))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<AuditLogDetails> getById(int id) {
    return _api.get<AuditLogDetails>(
      '/AuditLogs/$id',
      decode: (json) => AuditLogDetails.fromJson(json),
    );
  }
}

