class DashboardDeviceListItem {
  const DashboardDeviceListItem({required this.id, required this.name});

  final int id;
  final String name;

  static DashboardDeviceListItem fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException(
        'DashboardDeviceListItem: expected object',
      );
    }
    final map = Map<String, dynamic>.from(json);

    Object? pick(List<String> keys) {
      for (final k in keys) {
        if (map.containsKey(k)) return map[k];
      }
      return null;
    }

    int? parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '');
    }

    String? parseString(Object? v) {
      if (v is String) return v;
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    final id = parseInt(pick(const ['id', 'Id']));
    final name = parseString(pick(const ['name', 'Name']));
    if (id == null || name == null) {
      throw const FormatException(
        'DashboardDeviceListItem: invalid fields',
      );
    }
    return DashboardDeviceListItem(id: id, name: name);
  }
}
