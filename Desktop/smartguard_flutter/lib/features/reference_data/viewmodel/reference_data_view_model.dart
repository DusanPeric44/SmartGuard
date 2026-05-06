import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

class ReferenceEntityConfig {
  const ReferenceEntityConfig({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

class ReferenceDataViewModel extends ChangeNotifier {
  ReferenceDataViewModel({
    required ReferenceDataRepository repository,
    required List<ReferenceEntityConfig> entities,
  })  : _repository = repository,
        _entities = entities;

  final ReferenceDataRepository _repository;
  final List<ReferenceEntityConfig> _entities;

  List<ReferenceEntityConfig> get entities => List.unmodifiable(_entities);

  String _selectedEntityKey = '';
  String get selectedEntityKey => _selectedEntityKey;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReferenceItem> _items = const [];
  List<ReferenceItem> get items => _items;

  String _search = '';
  String get search => _search;

  Timer? _debounce;

  Future<void> init() async {
    _selectedEntityKey = _entities.isNotEmpty ? _entities.first.key : '';
    await load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> selectEntity(String key) async {
    _selectedEntityKey = key;
    _search = '';
    await load();
  }

  void setSearch(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      load();
    });
  }

  Future<void> load() async {
    if (_selectedEntityKey.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.list(_selectedEntityKey, search: _search);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReferenceItem?> createOrUpdate(ReferenceItem draft) async {
    if (_selectedEntityKey.isEmpty) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final isNew = draft.id.trim().isEmpty;
      final saved = isNew
          ? await _repository.create(_selectedEntityKey, draft)
          : await _repository.update(_selectedEntityKey, draft);
      await load();
      return saved;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    if (_selectedEntityKey.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.delete(_selectedEntityKey, id);
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
}

