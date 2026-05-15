import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';
import 'package:smartguard_flutter/features/manage_users/model/paged_result.dart';

abstract class UsersRepository {
  Future<PagedResult<ManagedUser>> list({
    String? term,
    required int pageNum,
    required int pageSize,
  });

  Future<ManagedUser> create({
    required String email,
    required UserRole role,
  });

  Future<ManagedUser> update({
    required String id,
    required String email,
    required UserRole role,
  });

  Future<void> delete(String id);
}

