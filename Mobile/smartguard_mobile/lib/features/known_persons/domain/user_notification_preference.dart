import 'known_person.dart';

class UserNotificationPreference {
  const UserNotificationPreference({
    required this.knownPerson,
    required this.enabled,
  });

  final KnownPerson knownPerson;
  final bool enabled;

  String get personId => knownPerson.id;

  UserNotificationPreference copyWith({bool? enabled}) {
    return UserNotificationPreference(
      knownPerson: knownPerson,
      enabled: enabled ?? this.enabled,
    );
  }

  static UserNotificationPreference fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('UserNotificationPreference: expected object');
    }

    final map = Map<String, dynamic>.from(json);

    final enabled = map['enabled'] == true;
    final knownPerson = KnownPerson.fromJson(map['knownPerson']);

    return UserNotificationPreference(knownPerson: knownPerson, enabled: enabled);
  }
}

