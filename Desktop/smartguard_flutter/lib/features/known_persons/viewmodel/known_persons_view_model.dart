import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/known_persons/data/known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';

class KnownPersonsViewModel extends ChangeNotifier {
  KnownPersonsViewModel({required KnownPersonsRepository repository})
    : _repository = repository;

  final KnownPersonsRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<KnownPerson> _items = const [];
  List<KnownPerson> get items => _items;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  String _term = '';
  String get term => _term;

  int _page = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = false;

  int get page => _page;
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
    _page = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final paged = await _repository.list(
        page: _page,
        pageSize: _pageSize,
        term: _term,
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
      _page++;
      final paged = await _repository.list(
        page: _page,
        pageSize: _pageSize,
        term: _term,
      );
      _items = [..._items, ...paged.result];
      _totalCount = paged.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      _page--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePerson({
    required String id,
    required String firstName,
    required String lastName,
  }) async {
    _rowBusy[id] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.update(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
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

  Future<bool> deletePerson(String id) async {
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

