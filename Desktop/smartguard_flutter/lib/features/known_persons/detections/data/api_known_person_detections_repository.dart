import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/known_persons/detections/data/known_person_detections_repository.dart';
import 'package:smartguard_flutter/features/known_persons/detections/model/known_person_detection_image.dart';
import 'package:smartguard_flutter/features/known_persons/model/paged_result.dart';

class ApiKnownPersonDetectionsRepository implements KnownPersonDetectionsRepository {
  ApiKnownPersonDetectionsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PagedResult<KnownPersonDetectionImage>> list({
    required String personId,
    required int page,
    required int pageSize,
  }) async {
    final parsedId = int.tryParse(personId.trim());
    if (parsedId == null) {
      throw Exception('Invalid personId');
    }

    final path = Uri(
      path: '/FaceDetectionEvents/person/$parsedId/images',
      queryParameters: <String, String>{
        'Page': page.toString(),
        'PageSize': pageSize.toString(),
      },
    ).toString();

    return _api.get<PagedResult<KnownPersonDetectionImage>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          return PagedResult<KnownPersonDetectionImage>(
            count: count,
            result: items
                .map((i) => KnownPersonDetectionImage.fromJson(i))
                .toList(growable: false),
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }
}

