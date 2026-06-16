import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/reference_data/data/reference_data_repository.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_entity.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_item.dart';

class ReferenceDataViewModel extends ChangeNotifier {
  ReferenceDataViewModel({required ReferenceDataRepository repository})
    : _repository = repository;

  final ReferenceDataRepository _repository;

  static const String _countriesPath = '/Countries';

  ReferenceEntity _entity = referenceEntities.first;
  ReferenceEntity get entity => _entity;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReferenceItem> _all = const [];

  final Map<int, bool> _rowBusy = <int, bool>{};
  Map<int, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  List<ReferenceItem> _countries = const [];

  /// Country options for the City form (populated from the DB).
  List<ReferenceItem> get countries => _countries;

  String _search = '';
  String get search => _search;

  Timer? _debounce;

  /// Items after applying the client-side name search.
  List<ReferenceItem> get items {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              (i.countryName ?? '').toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Future<void> init() => selectEntity(_entity, force: true);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> selectEntity(ReferenceEntity entity, {bool force = false}) async {
    if (!force && entity.id == _entity.id) return;
    _entity = entity;
    _search = '';
    _errorMessage = null;
    await load();
  }

  void setSearch(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), notifyListeners);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final paged = await _repository.list(_entity.path);
      _all = paged.result;
      if (_entity.hasCountry) {
        final countries = await _repository.list(_countriesPath);
        _countries = countries.result;
      }
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({required String name, int? countryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.create(_entity.path, name: name, countryId: countryId);
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, {required String name, int? countryId}) async {
    _rowBusy[id] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.update(
        _entity.path,
        id,
        name: name,
        countryId: countryId,
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

  Future<bool> delete(int id) async {
    _rowBusy[id] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.delete(_entity.path, id);
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
