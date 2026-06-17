import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/manage_users/data/users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';
import 'package:smartguard_flutter/features/manage_users/model/paged_result.dart';

class ApiUsersRepository implements UsersRepository {
  ApiUsersRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<ManagedUser>> list({
    String? term,
    required int pageNum,
    required int pageSize,
  }) async {
    final queryParameters = <String, String>{
      'PageNum': pageNum.toString(),
      'PageSize': pageSize.toString(),
    };
    final normalizedTerm = (term ?? '').trim();
    if (normalizedTerm.isNotEmpty) {
      queryParameters['term'] = normalizedTerm;
    }

    final path = Uri(
      path: '/users/',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PagedResult<ManagedUser>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<ManagedUser>(
            count: count,
            result: items
                .map((i) => ManagedUser.fromJson(i as Map<String, dynamic>))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ManagedUser> create({required String email, required UserRole role}) {
    return _api.post<ManagedUser>(
      '/users/',
      body: <String, Object?>{'email': email, 'role': userRoleToWire(role)},
      decode: (json) => ManagedUser.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ManagedUser> update({
    required String id,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) {
    return _api.request<ManagedUser>(
      method: 'PUT',
      path: '/users/$id',
      body: <String, Object?>{
        'firstName': firstName,
        'lastName': lastName,
        'role': userRoleToWire(role),
      },
      decode: (json) => ManagedUser.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _api.request<Object?>(method: 'DELETE', path: '/users/$id');
  }
}
