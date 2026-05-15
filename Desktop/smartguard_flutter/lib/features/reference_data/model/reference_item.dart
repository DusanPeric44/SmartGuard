import 'package:flutter/foundation.dart';

@immutable
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;

  ReferenceItem copyWith({
    String? id,
    String? code,
    String? name,
    bool? isActive,
  }) {
    return ReferenceItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}

