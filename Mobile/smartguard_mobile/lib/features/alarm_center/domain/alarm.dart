enum AlarmUiStatus { pending, confirmed, resolved, unknown }

class Alarm {
  const Alarm({
    required this.id,
    required this.title,
    required this.message,
    required this.statusName,
    required this.statusId,
    required this.createdAt,
    required this.linkedEventImagePath,
  });

  final int id;
  final String title;
  final String message;
  final String? statusName;
  final int? statusId;
  final DateTime? createdAt;
  final String? linkedEventImagePath;

  AlarmUiStatus get uiStatus {
    final byName = (statusName ?? '').trim().toLowerCase();
    if (byName.isNotEmpty) {
      if (byName.contains('pending') ||
          byName.contains('new') ||
          byName.contains('open')) {
        return AlarmUiStatus.pending;
      }
      if (byName.contains('confirm')) return AlarmUiStatus.confirmed;
      if (byName.contains('resolve') || byName.contains('dismiss')) {
        return AlarmUiStatus.resolved;
      }
    }

    switch (statusId) {
      case 1:
        return AlarmUiStatus.pending;
      case 2:
        return AlarmUiStatus.confirmed;
      case 3:
        return AlarmUiStatus.resolved;
      case 4:
        return AlarmUiStatus.resolved;
    }

    return AlarmUiStatus.unknown;
  }

  static Alarm fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Alarm: expected object');
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

    DateTime? parseDate(Object? v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

    String? parseString(Object? v) {
      final s = v?.toString();
      final t = s?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    }

    String? parseTitleFrom(Object? v) {
      if (v == null) return null;
      if (v is String) return parseString(v);
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final inner =
            m['location'] ??
            m['Location'] ??
            m['name'] ??
            m['Name'] ??
            m['deviceName'] ??
            m['DeviceName'];
        return parseString(inner);
      }
      return parseString(v);
    }

    String? parseLinkedEventImagePath(Object? v) {
      if (v == null) return null;
      if (v is String) return parseString(v);
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        Object? innerPick(List<String> keys) {
          for (final k in keys) {
            if (m.containsKey(k)) return m[k];
          }
          return null;
        }

        final raw = innerPick(const [
          'imageUrl',
          'ImageUrl',
          'snapshotUrl',
          'SnapshotUrl',
          'thumbnailUrl',
          'ThumbnailUrl',
          'image',
          'Image',
          'path',
          'Path',
          'url',
          'Url',
        ]);
        return parseString(raw);
      }
      return null;
    }

    final id = parseInt(pick(const ['id', 'Id']));
    if (id == null) {
      throw const FormatException('Alarm: missing id');
    }

    final device = pick(const ['device', 'Device']);
    final title =
        parseTitleFrom(pick(const [
          'deviceName',
          'DeviceName',
          'locationName',
          'LocationName',
          'title',
          'Title',
          'name',
          'Name',
        ])) ??
        parseTitleFrom(device) ??
        '';
    final message =
        parseString(pick(const [
          'message',
          'Message',
          'description',
          'Description',
          'text',
          'Text',
          'details',
          'Details',
        ])) ??
        '';

    final alertStatus = pick(const ['alertStatus', 'AlertStatus']);
    final statusName =
        parseTitleFrom(pick(const ['statusName', 'StatusName', 'status', 'Status'])) ??
        parseTitleFrom(alertStatus);
    final statusId =
        parseInt(pick(const ['statusId', 'StatusId'])) ??
        parseInt((alertStatus is Map) ? alertStatus['id'] ?? alertStatus['Id'] : null);

    final linkedEvent = pick(const ['linkedEvent', 'LinkedEvent']);
    final createdAt =
        parseDate(
          pick(const [
            'createdAt',
            'CreatedAt',
            'createdOn',
            'CreatedOn',
            'created',
            'Created',
            'timestamp',
            'Timestamp',
            'time',
            'Time',
            'date',
            'Date',
          ]),
        ) ??
        parseDate((linkedEvent is Map) ? linkedEvent['timestamp'] ?? linkedEvent['Timestamp'] : null);

    final linkedEventImagePath =
        parseLinkedEventImagePath(linkedEvent);

    return Alarm(
      id: id,
      title: title,
      message: message,
      statusName: statusName,
      statusId: statusId,
      createdAt: createdAt,
      linkedEventImagePath: linkedEventImagePath,
    );
  }
}
