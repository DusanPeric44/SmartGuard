import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/paged_result.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

class ApiReferenceDataRepository implements ReferenceDataRepository {
  ApiReferenceDataRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<ReferenceItem>> list(
    String path, {
    int page = 1,
    int pageSize = 100,
  }) {
    final query = Uri(
      path: path,
      queryParameters: <String, String>{
        'Page': page.toString(),
        'PageSize': pageSize.toString(),
      },
    ).toString();

    return _api.get<PagedResult<ReferenceItem>>(
      query,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<ReferenceItem>(
            count: count,
            result: items
                .map((i) => ReferenceItem.fromJson(i as Map<String, dynamic>))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<void> create(String path, {required String name}) async {
    await _api.post<Object?>(
      path,
      body: <String, Object?>{'name': name},
    );
  }

  @override
  Future<void> update(String path, int id, {required String name}) async {
    await _api.request<Object?>(
      method: 'PUT',
      path: '$path/$id',
      body: <String, Object?>{'name': name},
    );
  }

  @override
  Future<void> delete(String path, int id) async {
    await _api.request<Object?>(method: 'DELETE', path: '$path/$id');
  }
}
