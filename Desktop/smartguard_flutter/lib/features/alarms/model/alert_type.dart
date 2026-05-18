import 'dart:convert';

class AlertType {
  int? id;
  String? name;

  AlertType({this.id, this.name});

  factory AlertType.fromMap(Map<String, dynamic> data) =>
      AlertType(id: data['id'] as int?, name: data['name'] as String?);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [AlertType].
  factory AlertType.fromJson(String data) {
    return AlertType.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [AlertType] to a JSON string.
  String toJson() => json.encode(toMap());
}
