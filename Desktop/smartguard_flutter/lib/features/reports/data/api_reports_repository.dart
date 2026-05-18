import 'dart:typed_data';

import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/reports/data/reports_repository.dart';
import 'package:smartguard_flutter/features/reports/model/paged_result.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';

class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<ReportRow>> list({
    required int page,
    required int pageSize,
    DateTime? start,
    DateTime? end,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (start != null) {
      queryParameters['Start'] = start.toIso8601String();
    }
    if (end != null) {
      queryParameters['End'] = end.toIso8601String();
    }

    final path = Uri(
      path: '/Reports/',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<ReportRow>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<ReportRow>(
            count: count,
            result: items
                .map((i) => ReportRow.fromJson(i))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<void> generate({
    required DateTime start,
    required DateTime end,
  }) async {
    await _api.post<Object?>(
      '/Reports/generate/',
      body: <String, Object?>{
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
  }

  @override
  Future<Uint8List> download({required String path}) async {
    final normalized = _normalizePath(path);
    final url = normalized.startsWith('http')
        ? normalized
        : _api.baseUri.resolve(normalized).toString();
    return _api.getBytes(url);
  }
}

String _normalizePath(String rawPath) {
  final trimmed = rawPath.trim();
  if (trimmed.isEmpty) return '/';
  if (trimmed.startsWith('/')) return trimmed;
  return '/$trimmed';
}
