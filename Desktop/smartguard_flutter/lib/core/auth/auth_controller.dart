import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/auth_repository.dart';
import 'package:smartguard_flutter/core/auth/token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required TokenStore tokenStore,
  })  : _repository = repository,
        _tokenStore = tokenStore;

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();
    _isAuthenticated = await _repository.hasToken();
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await _repository.login(username: username, password: password);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await _tokenStore.clear();
    if (_isAuthenticated) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}

