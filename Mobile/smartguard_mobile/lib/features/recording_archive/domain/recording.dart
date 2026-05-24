class Recording {
  const Recording({
    required this.id,
    required this.timestamp,
    required this.durationSeconds,
    required this.filePath,
    required this.deviceName,
    required this.deviceLocation,
    required this.typeName,
  });

  final int id;
  final DateTime timestamp;
  final int durationSeconds;
  final String? filePath;
  final String deviceName;
  final String deviceLocation;
  final String typeName;

  String get title => deviceLocation.trim().isNotEmpty
      ? deviceLocation.trim()
      : deviceName.trim();

  String get durationLabel {
    final total = durationSeconds < 0 ? 0 : durationSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    final padded = seconds.toString().padLeft(2, '0');
    return '$minutes:$padded';
  }

  String? get fileName {
    final raw = filePath?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final uri = Uri.parse(raw);
      final last = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      if (last.trim().isEmpty) return null;
      return last;
    } catch (_) {
      final last = raw.split('?').first.split('/').where((e) => e.isNotEmpty);
      if (last.isEmpty) return null;
      return last.last;
    }
  }

  static Recording fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Recording: invalid json');
    final map = Map<String, dynamic>.from(json);

    T? pick<T>(String key) {
      final value = map[key];
      if (value is T) return value;
      return null;
    }

    int? pickInt(String key) {
      final v = map[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? pickString(String key) {
      final v = map[key];
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    DateTime? pickDate(String key) {
      final v = map[key];
      if (v is String) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    String parseNameFrom(Object? v) {
      if (v is String) return v;
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final name = m['name'] ?? m['Name'] ?? '';
        return name?.toString() ?? '';
      }
      return v?.toString() ?? '';
    }

    final id = pickInt('id') ?? pickInt('Id');
    if (id == null) throw const FormatException('Recording: missing id');

    final timestamp =
        pickDate('timestamp') ?? pickDate('Timestamp') ?? DateTime.fromMillisecondsSinceEpoch(0);

    final durationSeconds = pickInt('duration') ?? pickInt('Duration') ?? 0;
    final filePath = pickString('filePath') ?? pickString('FilePath');

    final device = pick<Object?>('device') ?? pick<Object?>('Device');
    String deviceName = '';
    String deviceLocation = '';
    if (device is Map) {
      final d = Map<String, dynamic>.from(device);
      deviceName = (d['name'] ?? d['Name'] ?? '').toString();
      deviceLocation = (d['location'] ?? d['Location'] ?? '').toString();
    }

    final recordingType =
        pick<Object?>('recordingType') ?? pick<Object?>('RecordingType');
    final typeName = parseNameFrom(recordingType).trim();

    return Recording(
      id: id,
      timestamp: timestamp,
      durationSeconds: durationSeconds,
      filePath: filePath,
      deviceName: deviceName,
      deviceLocation: deviceLocation,
      typeName: typeName,
    );
  }
}

