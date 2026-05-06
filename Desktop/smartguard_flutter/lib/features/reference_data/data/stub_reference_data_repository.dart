import 'dart:math';

import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

class StubReferenceDataRepository implements ReferenceDataRepository {
  StubReferenceDataRepository({int seed = 3}) : _rng = Random(seed) {
    _data = <String, List<ReferenceItem>>{
      'device_types': List.generate(
        8,
        (i) => ReferenceItem(
          id: 'dt-${i + 1}',
          code: 'DT${(i + 1).toString().padLeft(2, '0')}',
          name: 'Device Type ${(i + 1).toString().padLeft(2, '0')}',
          isActive: i % 7 != 0,
        ),
      ),
      'alarm_categories': List.generate(
        10,
        (i) => ReferenceItem(
          id: 'ac-${i + 1}',
          code: 'AC${(i + 1).toString().padLeft(2, '0')}',
          name: 'Alarm Category ${(i + 1).toString().padLeft(2, '0')}',
          isActive: i % 6 != 0,
        ),
      ),
      'zones': List.generate(
        12,
        (i) => ReferenceItem(
          id: 'z-${i + 1}',
          code: 'Z${(i + 1).toString().padLeft(2, '0')}',
          name: 'Zone ${(i + 1).toString().padLeft(2, '0')}',
          isActive: true,
        ),
      ),
    };
  }

  late final Map<String, List<ReferenceItem>> _data;
  final Random _rng;

  @override
  Future<List<ReferenceItem>> list(String entityKey, {String? search}) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final items = List<ReferenceItem>.from(_data[entityKey] ?? const []);
    final q = (search ?? '').trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((it) =>
            it.name.toLowerCase().contains(q) || it.code.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Future<ReferenceItem> create(String entityKey, ReferenceItem draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final list = _data.putIfAbsent(entityKey, () => <ReferenceItem>[]);
    final id = '${entityKey.substring(0, min(3, entityKey.length))}-${_rng.nextInt(999999)}';
    final item = draft.copyWith(id: id);
    list.insert(0, item);
    return item;
  }

  @override
  Future<ReferenceItem> update(String entityKey, ReferenceItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final list = _data.putIfAbsent(entityKey, () => <ReferenceItem>[]);
    final idx = list.indexWhere((x) => x.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    }
    return item;
  }

  @override
  Future<void> delete(String entityKey, String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final list = _data[entityKey];
    list?.removeWhere((x) => x.id == id);
  }
}

