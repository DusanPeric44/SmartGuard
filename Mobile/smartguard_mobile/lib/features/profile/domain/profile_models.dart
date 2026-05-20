enum UserRole { homeOwner, viewer, admin }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final UserRole role;

  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return '';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  static UserProfile fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('UserProfile: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final id = (map['id'] ?? map['userId'] ?? '').toString();
    final email = (map['email'] ?? '').toString();
    final firstName = (map['firstName'] ?? map['FirstName'] ?? '').toString();
    final lastName = (map['lastName'] ?? map['LastName'] ?? '').toString();
    final fullNameRaw = (map['fullName'] ?? map['name'] ?? '').toString();
    final username =
        (map['username'] ?? map['userName'] ?? map['userName'] ?? email)
            .toString();
    final roleRaw =
        (map['role'] ?? map['Role'] ?? map['userRole'] ?? map['UserRole'])
            ?.toString();

    if (id.trim().isEmpty || email.trim().isEmpty) {
      throw const FormatException('UserProfile: missing fields');
    }

    final (derivedFirst, derivedLast) = _deriveName(
      firstName: firstName,
      lastName: lastName,
      fullName: fullNameRaw,
    );

    final role = _parseRole(roleRaw);
    return UserProfile(
      id: id,
      firstName: derivedFirst,
      lastName: derivedLast,
      email: email,
      username: username,
      role: role,
    );
  }

  static (String, String) _deriveName({
    required String firstName,
    required String lastName,
    required String fullName,
  }) {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isNotEmpty || last.isNotEmpty) return (first, last);

    final raw = fullName.trim();
    if (raw.isEmpty) return ('', '');
    final parts = raw.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return ('', '');
    if (list.length == 1) return (list.first, '');
    return (list.first, list.sublist(1).join(' '));
  }

  static UserRole _parseRole(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return UserRole.admin;
    switch (value.toLowerCase()) {
      case 'homeowner':
        return UserRole.homeOwner;
      case 'viewer':
        return UserRole.viewer;
    }
    return UserRole.admin;
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
  };
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}
