import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

@immutable
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: (json['firstName'] ?? json['FirstName'] ?? '')
          .toString()
          .trim(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString().trim(),
      role: parseUserRole(json['role']?.toString()),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': userRoleToWire(role),
    };
  }

  ManagedUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
    );
  }
}
