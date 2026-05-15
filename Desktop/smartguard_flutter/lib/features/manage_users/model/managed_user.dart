import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

@immutable
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.role,
  });

  final String id;
  final String email;
  final UserRole role;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: parseUserRole(json['role']?.toString()),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'role': userRoleToWire(role),
    };
  }

  ManagedUser copyWith({
    String? id,
    String? email,
    UserRole? role,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

