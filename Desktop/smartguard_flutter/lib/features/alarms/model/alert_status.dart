import 'dart:convert';

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
