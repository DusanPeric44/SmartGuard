import 'user_notification_preference.dart';

class UserNotificationPreferencesResponse {
  const UserNotificationPreferencesResponse({
    required this.result,
    required this.count,
  });

  final List<UserNotificationPreference> result;
  final int count;

  static UserNotificationPreferencesResponse fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException(
        'UserNotificationPreferencesResponse: expected object',
      );
    }

    final map = Map<String, dynamic>.from(json);
    final rawResult = map['result'];
    if (rawResult is! List) {
      throw const FormatException(
        'UserNotificationPreferencesResponse: missing result',
      );
    }

    int parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    final result = rawResult
        .map(UserNotificationPreference.fromJson)
        .toList(growable: false);
    final count = parseInt(map['count']);

    return UserNotificationPreferencesResponse(
      result: result,
      count: count == 0 ? result.length : count,
    );
  }
}

