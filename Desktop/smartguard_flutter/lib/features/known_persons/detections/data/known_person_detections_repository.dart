import 'package:smartguard_flutter/features/known_persons/detections/model/known_person_detection_image.dart';
import 'package:smartguard_flutter/features/known_persons/model/paged_result.dart';

abstract interface class KnownPersonDetectionsRepository {
  Future<PagedResult<KnownPersonDetectionImage>> list({
    required String personId,
    required int page,
    required int pageSize,
  });
}

