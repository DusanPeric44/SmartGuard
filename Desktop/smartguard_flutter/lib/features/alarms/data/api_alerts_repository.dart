import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/alarms/data/alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_status.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_type.dart';
import 'package:smartguard_flutter/features/alarms/model/alerts_query.dart';
import 'package:smartguard_flutter/features/alarms/model/paged_result.dart';

class ApiAlertsRepository implements AlertsRepository {
  ApiAlertsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<AlertRow>> list(AlertsQuery query) async {
    final queryParameters = <String, String>{
      'Page': query.page.toString(),
      'PageSize': query.pageSize.toString(),
    };
    if (query.statusId != null) {
      queryParameters['StatusId'] = query.statusId.toString();
    }

    final path = Uri(
      path: '/Alerts',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<AlertRow>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<AlertRow>(
            count: count,
            result: items
                .map((i) => AlertRow.fromJson(i))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<List<AlertStatus>> listStatuses() async {
    final path = Uri(
      path: '/AlertStatuses',
      queryParameters: const <String, String>{'Page': '1', 'PageSize': '200'},
    ).toString();

    final page = await _api.get<Object?>(path, decode: (json) => json);
    if (page is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    final items = page['result'] as List? ?? const [];
    return items.map((e) => AlertStatus.fromJson(e)).toList(growable: false);
  }

  @override
  Future<List<AlertType>> listTypes() async {
    final path = Uri(
      path: '/AlertTypes',
      queryParameters: const <String, String>{'Page': '1', 'PageSize': '200'},
    ).toString();

    final page = await _api.get<Object?>(path, decode: (json) => json);
    if (page is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    final items = page['result'] as List? ?? const [];
    return items.map((e) => AlertType.fromJson(e)).toList(growable: false);
  }

  @override
  Future<AlertRow> confirm(int id) {
    return _api.post<AlertRow>(
      '/Alerts/$id/confirm',
      decode: (json) => AlertRow.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<AlertRow> resolve(int id) {
    return _api.post<AlertRow>(
      '/Alerts/$id/resolve',
      decode: (json) => AlertRow.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<AlertRow> dismiss(int id, {required String dismissalReason}) {
    return _api.post<AlertRow>(
      '/Alerts/$id/dismiss',
      body: <String, Object?>{'DismissalReason': dismissalReason},
      decode: (json) => AlertRow.fromJson(json as Map<String, dynamic>),
    );
  }
}
