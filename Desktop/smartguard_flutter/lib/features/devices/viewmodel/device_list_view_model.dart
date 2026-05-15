import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class DeviceListViewModel extends ChangeNotifier {
  DeviceListViewModel({required DevicesRepository repository}) : _repository = repository;

  final DevicesRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DeviceRow> _items = const [];
  List<DeviceRow> get items => _items;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  String _search = '';
  DeviceStatus? _status;

  int _page = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = false;

  Timer? _debounce;

  bool _isProvisioning = false;
  bool get isProvisioning => _isProvisioning;

  String? _provisioningStatus;
  String? get provisioningStatus => _provisioningStatus;

  String get search => _search;
  DeviceStatus? get status => _status;
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await load();
  }


  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setSearch(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      load();
    });
  }

  Future<void> setStatus(DeviceStatus? status) async {
    _status = status;
    await load();
  }

  Future<void> load() async {
    _page = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagedResult = await _repository.list(
        search: _search,
        status: _status,
        page: _page,
        pageSize: _pageSize,
      );
      _items = pagedResult.result;
      _totalCount = pagedResult.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();
    try {
      _page++;
      final pagedResult = await _repository.list(
        search: _search,
        status: _status,
        page: _page,
        pageSize: _pageSize,
      );
      _items = [..._items, ...pagedResult.result];
      _totalCount = pagedResult.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      _page--; // Revert page on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<String?> provisionDevice({
    required String ssid,
    required String password,
    required String registrationKey,
  }) async {
    _isProvisioning = true;
    _provisioningStatus = 'Slanje podataka uređaju...';
    notifyListeners();

    try {
      // 1. Send to ESP32 via repository
      await _repository.provisionDevice(
        ssid: ssid,
        password: password,
        registrationKey: registrationKey,
      );

      // 2. Poll for new device
      _provisioningStatus = 'Čekanje na registraciju uređaja...';
      notifyListeners();

      final existingIds = _items.map((e) => e.id).toSet();
      final startTime = DateTime.now();
      
      while (DateTime.now().difference(startTime).inSeconds < 30) {
        await Future<void>.delayed(const Duration(seconds: 3));
        
        try {
          final pagedResult = await _repository.list();
          final currentItems = pagedResult.result;
          final newDevice = currentItems.firstWhere(
            (it) => !existingIds.contains(it.id),
            orElse: () => const DeviceRow(
              id: '',
              name: '',
              ipAddress: '',
              status: DeviceStatus.offline,
              isActive: false,
              storageUsedGb: 0,
              storageTotalGb: 0,
            ),
          );

          if (newDevice.id.isNotEmpty) {
            _items = currentItems;
            return newDevice.id;
          }
        } catch (_) {
          // Ignore polling errors
        }
      }

      return null;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return null;
    } finally {
      _isProvisioning = false;
      _provisioningStatus = null;
      notifyListeners();
    }
  }

  Future<bool> setActive(String deviceId, bool isActive) async {
    _rowBusy[deviceId] = true;
    notifyListeners();
    try {
      final updated = await _repository.setActive(deviceId, isActive);
      final idx = _items.indexWhere((d) => d.id == deviceId);
      if (idx >= 0) {
        final mutable = _items.toList(growable: true);
        mutable[idx] = updated;
        _items = mutable.toList(growable: false);
      }
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _rowBusy.remove(deviceId);
      notifyListeners();
    }
  }
}
