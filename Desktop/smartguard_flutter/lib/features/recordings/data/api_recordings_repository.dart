import 'dart:typed_data';

import 'package:smartguard_flutter/core/config/app_config.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_device_option.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

class ApiRecordingsRepository implements RecordingsRepository {
  ApiRecordingsRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<PageResult<RecordingRow>> list(RecordingsQuery query) async {
    final queryParameters = <String, String>{
      'page': query.page.toString(),
      'pageSize': query.pageSize.toString(),
    };

    final term = (query.search ?? '').trim();
    if (term.isNotEmpty) {
      queryParameters['Term'] = term;
    }
    if (query.deviceId != null && query.deviceId! > 0) {
      queryParameters['DeviceId'] = query.deviceId.toString();
    }
    if (query.type != null) {
      queryParameters['RecordingTypeId'] = _typeToId(query.type!).toString();
    }
    if (query.status != null) {
      queryParameters['RecordingStatusId'] = _statusToId(
        query.status!,
      ).toString();
    }
    if (query.from != null) {
      queryParameters['Start'] = query.from!.toIso8601String();
    }
    if (query.to != null) {
      queryParameters['End'] = query.to!.toIso8601String();
    }

    final path = Uri(
      path: '/Recordings',
      queryParameters: queryParameters,
    ).toString();

    return _api.get<PageResult<RecordingRow>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final count = (json['count'] as num?)?.toInt() ?? 0;
          final items = json['result'] as List? ?? const [];
          final rows = items
              .map((i) => RecordingRow.fromJson(i as Map<String, dynamic>))
              .toList(growable: false);
          return PageResult<RecordingRow>(
            items: rows,
            total: count,
            page: query.page,
            pageSize: query.pageSize,
          );
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<List<RecordingDeviceOption>> listDevices() async {
    final path = Uri(
      path: '/devices/my',
      queryParameters: const <String, String>{'page': '1', 'pageSize': '200'},
    ).toString();

    return _api.get<List<RecordingDeviceOption>>(
      path,
      decode: (json) {
        if (json is Map<String, dynamic>) {
          final items = json['result'] as List? ?? const [];
          final out = <RecordingDeviceOption>[];
          for (final i in items) {
            if (i is! Map<String, dynamic>) continue;
            final id = int.tryParse(i['id']?.toString() ?? '');
            final name = i['name']?.toString() ?? '';
            if (id == null) continue;
            out.add(RecordingDeviceOption(id: id, name: name));
          }
          return out;
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<void> softDelete(int recordingId) async {
    await _api.request<Object?>(
      method: 'DELETE',
      path: '/Recordings/$recordingId',
    );
  }

  @override
  Future<Uint8List> download(String fileName) async {
    final normalized = Uri.encodeComponent(fileName);
    final url = AppConfig.archiveBaseUri
        .resolve('/api/VideoArchive/download/$normalized')
        .toString();
    return _api.getBytes(url);
  }
}

int _typeToId(RecordingType type) => type.index + 1;

int _statusToId(RecordingStatus status) => status.index + 1;
