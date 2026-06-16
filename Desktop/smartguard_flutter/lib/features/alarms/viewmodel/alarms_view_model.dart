import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/alarms/data/alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/model/alerts_query.dart';
import 'package:smartguard_flutter/features/alarms/model/paged_result.dart';

class AlarmsViewModel extends ChangeNotifier {
  AlarmsViewModel({required AlertsRepository repository})
    : _repository = repository;

  final AlertsRepository _repository;

  AlertsQuery _query = const AlertsQuery();
  AlertsQuery get query => _query;

  PagedResult<AlertRow>? _page;
  PagedResult<AlertRow>? get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final bool _isBootstrapping = false;
  bool get isBootstrapping => _isBootstrapping;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _selectedAlertId;
  int? get selectedAlertId => _selectedAlertId;

  AlertRow? _selectedAlert;
  AlertRow? get selectedAlert => _selectedAlert;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  int _reqId = 0;

  Future<void> init() async {
    await load();
  }

  Future<void> bootstrap() async {
    await load();
  }

  Future<void> load() async {
    _reqId++;
    final current = _reqId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.list(_query);
      if (current != _reqId) return;
      _page = res;
      _ensureSelectedStillValid();
    } catch (e) {
      if (current != _reqId) return;
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      if (current == _reqId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void select(AlertRow row) {
    _selectedAlertId = row.id;
    _selectedAlert = row;
    notifyListeners();
  }

  Future<void> changePage(int page) async {
    if (page < 1) return;
    _query = _query.copyWith(page: page);
    await load();
  }

  Future<void> changePageSize(int size) async {
    _query = _query.copyWith(pageSize: size, page: 1);
    await load();
  }

  Future<void> setStatusFilter(String? statusName) async {
    _query = AlertsQuery(
      statusName: statusName,
      page: 1,
      pageSize: _query.pageSize,
    );
    await load();
  }

  Future<bool> confirmSelected() async {
    final row = _selectedAlert;
    if (row == null) return false;
    return _runAction(row.id!, () => _repository.confirm(row.id!));
  }

  Future<bool> resolveSelected() async {
    final row = _selectedAlert;
    if (row == null) return false;
    return _runAction(row.id!, () => _repository.resolve(row.id!));
  }

  Future<bool> dismissSelected(String reason) async {
    final row = _selectedAlert;
    if (row == null) return false;
    return _runAction(
      row.id!,
      () => _repository.dismiss(row.id!, dismissalReason: reason),
    );
  }

  Future<bool> _runAction(int id, Future<AlertRow> Function() call) async {
    final key = id.toString();
    _rowBusy[key] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await call();
      _selectedAlertId = updated.id;
      _selectedAlert = updated;
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return false;
    } finally {
      _rowBusy.remove(key);
      notifyListeners();
    }
  }

  void _ensureSelectedStillValid() {
    final selectedId = _selectedAlertId;
    final page = _page;
    if (selectedId == null || page == null) return;
    final found = page.result.where((e) => e.id == selectedId).toList();
    if (found.isEmpty) return;
    _selectedAlert = found.first;
  }
}
