import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';

class DeviceDetailsViewModel extends ChangeNotifier {
  DeviceDetailsViewModel({
    required DevicesRepository repository,
    required this.deviceId,
  }) : _repository = repository;

  final DevicesRepository _repository;
  final String deviceId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DeviceDetails? _details;
  DeviceDetails? get details => _details;

  List<DeviceUser> _allUsers = const [];
  List<DeviceUser> get allUsers => _allUsers;

  Future<void> init() async {
    await Future.wait([
      load(),
      loadUsers(),
    ]);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _repository.getDetails(deviceId);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _allUsers = await _repository.listUsers();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveAssignments(List<String> userIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _repository.assignUsers(deviceId, userIds);
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setActive(bool value) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.setActive(deviceId, value);
      if (_details != null) {
        _details = DeviceDetails(
          device: updated,
          assignedUsers: _details!.assignedUsers,
          lastSeenAt: _details!.lastSeenAt,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

