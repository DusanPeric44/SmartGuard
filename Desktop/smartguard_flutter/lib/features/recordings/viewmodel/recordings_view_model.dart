import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/recordings/data/recordings_repository.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

class RecordingsViewModel extends ChangeNotifier {
  RecordingsViewModel({
    required RecordingsRepository repository,
  }) : _repository = repository;

  final RecordingsRepository _repository;

  RecordingsQuery _query = const RecordingsQuery();
  RecordingsQuery get query => _query;

  PageResult<RecordingRow>? _page;
  PageResult<RecordingRow>? get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  Timer? _searchDebounce;
  int _reqId = 0;

  Future<void> init() async {
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
    String? deviceId,
    RecordingType? type,
    RecordingStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    _query = _query.copyWith(
      deviceId: (deviceId == null || deviceId.trim().isEmpty) ? null : deviceId,
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

  Future<void> changeSort(RecordingsSortBy sortBy, SortDir dir) async {
    _query = _query.copyWith(sortBy: sortBy, sortDir: dir, page: 1);
    await load();
  }

  Future<void> softDelete(String recordingId) async {
    _rowBusy[recordingId] = true;
    notifyListeners();
    try {
      await _repository.softDelete(recordingId);
      await load();
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
    } finally {
      _rowBusy.remove(recordingId);
      notifyListeners();
    }
  }

  Future<Uint8List?> download(String recordingId) async {
    _rowBusy[recordingId] = true;
    notifyListeners();
    try {
      return await _repository.download(recordingId);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return null;
    } finally {
      _rowBusy.remove(recordingId);
      notifyListeners();
    }
  }
}
