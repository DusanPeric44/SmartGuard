import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/known_persons/data/known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/model/paged_result.dart';

class ApiKnownPersonsRepository implements KnownPersonsRepository {
  ApiKnownPersonsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<KnownPerson>> list({
    required int page,
    required int pageSize,
    String? term,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final normalizedTerm = (term ?? '').trim();
    if (normalizedTerm.isNotEmpty) {
      queryParameters['term'] = normalizedTerm;
    }

    final path = Uri(
      path: '/knownPersons/search',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<KnownPerson>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<KnownPerson>(
            count: count,
            result: items
                .map((i) => KnownPerson.fromJson(i as Map<String, dynamic>))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<KnownPerson> update({
    required String id,
    required String firstName,
    required String lastName,
  }) {
    return _api.request<KnownPerson>(
      method: 'PUT',
      path: '/knownPersons/$id',
      body: <String, Object?>{'firstName': firstName, 'lastName': lastName},
      decode: (json) => KnownPerson.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _api.request<Object?>(method: 'DELETE', path: '/knownPersons/$id');
  }

  @override
  Future<void> combine({
    required String primaryPersonId,
    required String secondaryPersonId,
  }) async {
    await _api.request<Object?>(
      method: 'POST',
      path: '/KnownPersons/combine',
      body: <String, Object?>{
        'primaryPersonId': int.parse(primaryPersonId),
        'secondaryPersonId': int.parse(secondaryPersonId),
      },
    );
  }
}
