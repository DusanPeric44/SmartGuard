import 'package:flutter/foundation.dart';

/// A single reference / lookup record. Covers the simple `{id, name}` tables
/// as well as `City`, which additionally carries a `country` FK.
@immutable
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
    this.countryId,
    this.countryName,
  });

  final int id;
  final String name;
  final int? countryId;
  final String? countryName;

  static ReferenceItem fromJson(Map<String, dynamic> json) {
    final country = json['country'];
    return ReferenceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      countryId: (json['countryId'] as num?)?.toInt(),
      countryName: country is Map ? country['name']?.toString() : null,
    );
  }
}
