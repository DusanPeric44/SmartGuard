import 'dart:convert';

class ReportType {
  final int id;
  final String name;

  const ReportType({required this.id, required this.name});

  factory ReportType.fromMap(Map<String, dynamic> data) =>
      ReportType(id: data['id'] as int, name: data['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ReportType].
  factory ReportType.fromJson(String data) {
    return ReportType.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ReportType] to a JSON string.
  String toJson() => json.encode(toMap());
}
