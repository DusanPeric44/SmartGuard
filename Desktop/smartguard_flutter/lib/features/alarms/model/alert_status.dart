import 'dart:convert';

/// Centralized alert status names (as returned by the API) so these
/// "magic strings" live in one place instead of being scattered across
/// filters, status chips and the details panel.
class AlertStatusNames {
  const AlertStatusNames._();

  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String resolved = 'Resolved';
  static const String dismissed = 'Dismissed';
}

class AlertStatus {
  int? id;
  String? name;

  AlertStatus({this.id, this.name});

  factory AlertStatus.fromMap(Map<String, dynamic> data) =>
      AlertStatus(id: data['id'] as int?, name: data['name'] as String?);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [AlertStatus].
  factory AlertStatus.fromJson(String data) {
    return AlertStatus.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [AlertStatus] to a JSON string.
  String toJson() => json.encode(toMap());
}
