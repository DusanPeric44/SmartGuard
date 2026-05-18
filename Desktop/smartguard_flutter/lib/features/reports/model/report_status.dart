import 'dart:convert';

class ReportStatus {
  final int id;
  final String name;

  const ReportStatus({required this.id, required this.name});

  factory ReportStatus.fromMap(Map<String, dynamic> data) =>
      ReportStatus(id: data['id'] as int, name: data['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ReportStatus].
  factory ReportStatus.fromJson(String data) {
    return ReportStatus.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ReportStatus] to a JSON string.
  String toJson() => json.encode(toMap());
}
