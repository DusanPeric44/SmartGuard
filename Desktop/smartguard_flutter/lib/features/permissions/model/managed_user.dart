import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

@immutable
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.role,
  });

  final String id;
  final String username;
  final UserRole role;

  ManagedUser copyWith({
    String? id,
    String? username,
    UserRole? role,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
    );
  }
}

