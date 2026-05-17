class KnownPerson {
  const KnownPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.pictureUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? pictureUrl;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? id : full;
  }

  static KnownPerson fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('KnownPerson: expected object');
    }

    final map = Map<String, dynamic>.from(json);

    final id = (map['id'] ?? map['personId'] ?? '').toString();
    final firstName = (map['firstname'] ?? map['firstName'] ?? '').toString();
    final lastName = (map['lastname'] ?? map['lastName'] ?? '').toString();
    final pictureRaw = map['picture'] ?? map['pictureUrl'] ?? map['imageUrl'];
    final pictureUrl = pictureRaw?.toString().trim();

    if (id.trim().isEmpty) {
      throw const FormatException('KnownPerson: missing id');
    }

    return KnownPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      pictureUrl: pictureUrl == null || pictureUrl.isEmpty ? null : pictureUrl,
    );
  }
}

