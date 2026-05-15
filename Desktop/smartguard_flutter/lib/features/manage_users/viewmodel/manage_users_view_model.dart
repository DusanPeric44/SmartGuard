import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/manage_users/data/users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';

class ManageUsersViewModel extends ChangeNotifier {
  ManageUsersViewModel({required UsersRepository repository})
    : _repository = repository;

  final UsersRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ManagedUser> _items = const [];
  List<ManagedUser> get items => _items;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  String _term = '';
  String get term => _term;

  int _pageNum = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = false;

  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  Timer? _debounce;

  Future<void> init() async {
    await load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setTerm(String value) {
    _term = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      load();
    });
  }

  Future<void> load() async {
    _pageNum = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final paged = await _repository.list(
        term: _term,
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
      _items = paged.result;
      _totalCount = paged.count;
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
      _pageNum++;
      final paged = await _repository.list(
        term: _term,
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
      _items = [..._items, ...paged.result];
      _totalCount = paged.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      _pageNum--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String email,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.create(email: email, role: role);
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String id,
    required String email,
    required UserRole role,
  }) async {
    _rowBusy[id] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.update(id: id, email: email, role: role);
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _rowBusy.remove(id);
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _rowBusy[id] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.delete(id);
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return false;
    } finally {
      _rowBusy.remove(id);
      notifyListeners();
    }
  }
}

