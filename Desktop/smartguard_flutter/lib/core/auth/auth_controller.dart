import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/auth_repository.dart';
import 'package:smartguard_flutter/core/auth/token_store.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required TokenStore tokenStore,
  }) : _repository = repository,
       _tokenStore = tokenStore;

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  UserRole _role = UserRole.viewer;
  UserRole get role => _role;

  String? _registrationKey;
  String? get registrationKey => _registrationKey;

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();
    _isAuthenticated = await _repository.hasToken();
    _role = (await _tokenStore.getRole()) ?? UserRole.viewer;
    _registrationKey = await _tokenStore.getRegistrationKey();

    if (_isAuthenticated &&
        _role == UserRole.admin &&
        _registrationKey == null) {
      _registrationKey = await _repository.fetchRegistrationKey();
      if (_registrationKey != null) {
        await _tokenStore.setRegistrationKey(_registrationKey!);
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await _repository.login(username: username, password: password);
    _isAuthenticated = true;
    _role = (await _tokenStore.getRole()) ?? UserRole.viewer;

    if (_role == UserRole.admin) {
      _registrationKey = await _repository.fetchRegistrationKey();
      if (_registrationKey != null) {
        await _tokenStore.setRegistrationKey(_registrationKey!);
      }
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _isAuthenticated = false;
    _role = UserRole.viewer;
    _registrationKey = null;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await _tokenStore.clear();
    if (_isAuthenticated) {
      _isAuthenticated = false;
      _role = UserRole.viewer;
      _registrationKey = null;
      notifyListeners();
    }
  }
}
