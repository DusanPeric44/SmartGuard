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

  Timer? _debounce;

  String get search => _search;
  DeviceStatus? get status => _status;

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.list(search: _search, status: _status);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
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
