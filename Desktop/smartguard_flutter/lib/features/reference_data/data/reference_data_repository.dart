import 'package:smartguard_flutter/features/reference_data/model/paged_result.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

abstract interface class ReferenceDataRepository {
  Future<PagedResult<ReferenceItem>> list(
    String path, {
    int page,
    int pageSize,
  });

  Future<void> create(String path, {required String name});

  Future<void> update(
    String path,
    int id, {
    required String name,
  });

  Future<void> delete(String path, int id);
}
