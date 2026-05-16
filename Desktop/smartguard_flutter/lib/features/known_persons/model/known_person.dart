import 'package:flutter/foundation.dart';

@immutable
class KnownPerson {
  const KnownPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.picture,
    required this.lastSeenAt,
    required this.location,
    required this.detectionCount,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String picture;
  final DateTime lastSeenAt;
  final String location;
  final int detectionCount;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  bool get isIntruder => fullName.toLowerCase().contains('intruder');

  Map<String, Object?> toUpdateJson() {
    return <String, Object?>{'firstName': firstName, 'lastName': lastName};
  }

  factory KnownPerson.fromJson(Map<String, dynamic> json) {
    return KnownPerson(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      lastSeenAt:
          DateTime.tryParse(json['lastSeenAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      location: json['location']?.toString() ?? '',
      detectionCount: (json['detectionCount'] as num?)?.toInt() ?? 0,
    );
  }

  KnownPerson copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? photoUrl,
    DateTime? lastSeenAt,
    String? location,
    int? detections,
  }) {
    return KnownPerson(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      picture: photoUrl ?? this.picture,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      location: location ?? this.location,
      detectionCount: detections ?? this.detectionCount,
    );
  }
}
