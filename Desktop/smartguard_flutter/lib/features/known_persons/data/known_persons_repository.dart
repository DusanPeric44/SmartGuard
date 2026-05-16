import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/model/paged_result.dart';

abstract class KnownPersonsRepository {
  Future<PagedResult<KnownPerson>> list({
    required int page,
    required int pageSize,
    String? term,
  });

  Future<KnownPerson> update({
    required String id,
    required String firstName,
    required String lastName,
  });

  Future<void> delete(String id);
}

