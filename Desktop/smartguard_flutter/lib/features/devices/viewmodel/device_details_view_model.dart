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

  bool _isEditingName = false;
  bool get isEditingName => _isEditingName;

  String _pendingName = '';
  String get pendingName => _pendingName;

  Future<void> init() async {
    await Future.wait([load(), loadUsers()]);
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

  void beginEditName() {
    _pendingName = _details?.device.name ?? '';
    _isEditingName = true;
    notifyListeners();
  }

  void setPendingName(String value) {
    _pendingName = value;
    notifyListeners();
  }

  void cancelEditName() {
    _pendingName = '';
    _isEditingName = false;
    notifyListeners();
  }

  Future<bool> renameDevice() async {
    final next = _pendingName.trim();
    final current = _details?.device.name ?? '';
    if (next.isEmpty || next == current) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _repository.renameDevice(deviceId, next);
      _pendingName = '';
      _isEditingName = false;
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
