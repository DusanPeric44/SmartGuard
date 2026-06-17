import 'package:flutter/foundation.dart';

/// A single reference / lookup record for a simple `{id, name}` table.
@immutable
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  static ReferenceItem fromJson(Map<String, dynamic> json) {
    return ReferenceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
