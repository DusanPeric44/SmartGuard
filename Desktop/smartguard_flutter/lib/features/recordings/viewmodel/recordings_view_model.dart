import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_device_option.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

class RecordingsViewModel extends ChangeNotifier {
  RecordingsViewModel({required RecordingsRepository repository})
    : _repository = repository;

  final RecordingsRepository _repository;

  RecordingsQuery _query = const RecordingsQuery();
  RecordingsQuery get query => _query;

  PageResult<RecordingRow>? _page;
  PageResult<RecordingRow>? get page => _page;

  List<RecordingDeviceOption> _devices = const [];
  List<RecordingDeviceOption> get devices => _devices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  Timer? _searchDebounce;
  int _reqId = 0;

  Future<void> init() async {
    await loadDevices();
    await load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    _reqId++;
    final current = _reqId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.list(_query);
      if (current != _reqId) return;
      _page = res;
    } catch (e) {
      if (current != _reqId) return;
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      if (current == _reqId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _query = _query.copyWith(
        search: value.trim().isEmpty ? null : value.trim(),
        page: 1,
      );
      load();
    });
  }

  Future<void> applyFilters({
    int? deviceId,
    RecordingType? type,
    RecordingStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    _query = _query.copyWith(
      deviceId: deviceId,
      type: type,
      status: status,
      from: from,
      to: to,
      page: 1,
    );
    await load();
  }

  Future<void> resetFilters() async {
    _query = const RecordingsQuery();
    await load();
  }

  Future<void> changePage(int page) async {
    if (page < 1) return;
    _query = _query.copyWith(page: page);
    await load();
  }

  Future<void> changePageSize(int size) async {
    _query = _query.copyWith(pageSize: size, page: 1);
    await load();
  }

  Future<void> loadDevices() async {
    try {
      final res = await _repository.listDevices();
      _devices = res;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> softDelete(int recordingId) async {
    final key = recordingId.toString();
    _rowBusy[key] = true;
    notifyListeners();
    try {
      await _repository.softDelete(recordingId);
      await load();
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
    } finally {
      _rowBusy.remove(key);
      notifyListeners();
    }
  }

  Future<Uint8List?> download(String rowKey, String fileName) async {
    _rowBusy[rowKey] = true;
    notifyListeners();
    try {
      return await _repository.download(fileName);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return null;
    } finally {
      _rowBusy.remove(rowKey);
      notifyListeners();
    }
  }
}
