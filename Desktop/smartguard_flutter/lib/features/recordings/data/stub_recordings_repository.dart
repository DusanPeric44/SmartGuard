import 'dart:math';
import 'dart:typed_data';

import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

class StubRecordingsRepository implements RecordingsRepository {
  StubRecordingsRepository({
    this.seed = 7,
    this.totalItems = 2500,
  }) : _rng = Random(seed);

  final int seed;
  final int totalItems;
  final Random _rng;

  late final List<_StubDevice> _devices = List.generate(
    18,
    (i) => _StubDevice(
      id: 'dev-${i + 1}',
      name: 'Camera ${(i + 1).toString().padLeft(2, '0')}',
    ),
  );

  late final List<RecordingRow> _all = _generate();

  final Map<String, DateTime> _deleted = <String, DateTime>{};

  @override
  Future<PageResult<RecordingRow>> list(RecordingsQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    Iterable<RecordingRow> items = _all.map((r) {
      final deletedAt = _deleted[r.id];
      if (deletedAt == null) return r;
      return RecordingRow(
        id: r.id,
        deviceId: r.deviceId,
        deviceName: r.deviceName,
        startedAt: r.startedAt,
        durationSeconds: r.durationSeconds,
        sizeBytes: r.sizeBytes,
        type: r.type,
        status: RecordingStatus.deleted,
        deletedAt: deletedAt,
      );
    });

    if (query.deviceId != null && query.deviceId!.trim().isNotEmpty) {
      items = items.where((r) => r.deviceId == query.deviceId);
    }
    if (query.type != null) {
      items = items.where((r) => r.type == query.type);
    }
    if (query.status != null) {
      items = items.where((r) => r.status == query.status);
    }
    if (query.from != null) {
      items = items.where((r) => !r.startedAt.isBefore(query.from!));
    }
    if (query.to != null) {
      items = items.where((r) => !r.startedAt.isAfter(query.to!));
    }
    final search = (query.search ?? '').trim().toLowerCase();
    if (search.isNotEmpty) {
      items = items.where((r) {
        return r.deviceName.toLowerCase().contains(search) ||
            r.id.toLowerCase().contains(search);
      });
    }

    final sorted = items.toList(growable: false);
    sorted.sort((a, b) {
      int cmp;
      switch (query.sortBy) {
        case RecordingsSortBy.startedAt:
          cmp = a.startedAt.compareTo(b.startedAt);
          break;
        case RecordingsSortBy.deviceName:
          cmp = a.deviceName.compareTo(b.deviceName);
          break;
        case RecordingsSortBy.status:
          cmp = a.status.index.compareTo(b.status.index);
          break;
        case RecordingsSortBy.sizeBytes:
          cmp = a.sizeBytes.compareTo(b.sizeBytes);
          break;
        case RecordingsSortBy.durationSeconds:
          cmp = a.durationSeconds.compareTo(b.durationSeconds);
          break;
      }
      return query.sortDir == SortDir.asc ? cmp : -cmp;
    });

    final total = sorted.length;
    final pageSize = query.pageSize.clamp(5, 200);
    final page = max(1, query.page);
    final start = (page - 1) * pageSize;
    final end = min(start + pageSize, total);
    final pageItems = (start >= total) ? <RecordingRow>[] : sorted.sublist(start, end);

    return PageResult<RecordingRow>(
      items: pageItems,
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> softDelete(String recordingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _deleted[recordingId] = DateTime.now();
  }

  @override
  Future<Uint8List> download(String recordingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final bytes = Uint8List(128);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _rng.nextInt(255);
    }
    return bytes;
  }

  List<RecordingRow> _generate() {
    final now = DateTime.now();
    final list = <RecordingRow>[];
    for (var i = 0; i < totalItems; i++) {
      final device = _devices[_rng.nextInt(_devices.length)];
      final startedAt = now.subtract(Duration(
        minutes: _rng.nextInt(60 * 24 * 30),
      ));
      final duration = 10 + _rng.nextInt(60 * 10);
      final type = RecordingType.values[_rng.nextInt(RecordingType.values.length)];
      final status = _rng.nextDouble() < 0.03
          ? RecordingStatus.failed
          : (_rng.nextDouble() < 0.08 ? RecordingStatus.processing : RecordingStatus.available);
      final sizeBytes = duration * (220000 + _rng.nextInt(450000));

      list.add(
        RecordingRow(
          id: 'rec-${(i + 1).toString().padLeft(6, '0')}',
          deviceId: device.id,
          deviceName: device.name,
          startedAt: startedAt,
          durationSeconds: duration,
          sizeBytes: sizeBytes,
          type: type,
          status: status,
        ),
      );
    }
    return list;
  }
}

class _StubDevice {
  const _StubDevice({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

