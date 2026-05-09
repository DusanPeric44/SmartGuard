class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String username;
  final String? avatarUrl;

  static UserProfile fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('UserProfile: expected object');
    }

    final map = Map<String, dynamic>.from(json);
    final id = (map['id'] ?? map['userId'] ?? '').toString();
    final fullName = (map['fullName'] ?? map['name'] ?? '').toString();
    final email = (map['email'] ?? '').toString();
    final username = (map['username'] ?? map['userName'] ?? '').toString();
    final avatarUrl = map['avatarUrl']?.toString();

    if (id.trim().isEmpty || email.trim().isEmpty) {
      throw const FormatException('UserProfile: missing fields');
    }

    return UserProfile(
      id: id,
      fullName: fullName,
      email: email,
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({required this.fullName, required this.email});

  final String fullName;
  final String email;

  Map<String, dynamic> toJson() => {'fullName': fullName, 'email': email};
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
