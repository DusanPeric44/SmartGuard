import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

abstract class ReferenceDataRepository {
  Future<List<ReferenceItem>> list(String entityKey, {String? search});
  Future<ReferenceItem> create(String entityKey, ReferenceItem draft);
  Future<ReferenceItem> update(String entityKey, ReferenceItem item);
  Future<void> delete(String entityKey, String id);
}

