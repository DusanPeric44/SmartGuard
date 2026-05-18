import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/audit_logs/data/audit_logs_repository.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_query.dart';
import 'package:smartguard_flutter/features/audit_logs/model/paged_result.dart';

class AuditLogsViewModel extends ChangeNotifier {
  AuditLogsViewModel({required AuditLogsRepository repository})
    : _repository = repository;

  final AuditLogsRepository _repository;

  AuditLogQuery _query = const AuditLogQuery();
  AuditLogQuery get query => _query;

  PagedResult<AuditLogRow>? _page;
  PagedResult<AuditLogRow>? get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  List<String> _userOptions = const [];
  List<String> get userOptions => _userOptions;

  List<String> _actionOptions = const [];
  List<String> get actionOptions => _actionOptions;

  List<String> _resourceOptions = const [];
  List<String> get resourceOptions => _resourceOptions;

  List<String> _statusOptions = const [];
  List<String> get statusOptions => _statusOptions;

  Timer? _searchDebounce;
  int _reqId = 0;

  Future<void> init() async {
    await load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
      _deriveOptions(res.result);
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

  void setSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      _query = _query.copyWith(
        text: trimmed.isEmpty ? null : trimmed,
        page: 1,
      );
      load();
    });
  }

  Future<void> applyFilters({
    String? userId,
    String? action,
    String? resource,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    _query = _query.copyWith(
      userId: _normalize(userId),
      action: _normalize(action),
      resource: _normalize(resource),
      status: _normalize(status),
      from: from,
      to: to,
      page: 1,
    );
    await load();
  }

  Future<void> resetFilters() async {
    _query = const AuditLogQuery();
    await load();
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

  Future<AuditLogDetails?> loadDetails(int id) async {
    final key = id.toString();
    _rowBusy[key] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _repository.getById(id);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return null;
    } finally {
      _rowBusy.remove(key);
      notifyListeners();
    }
  }

  void _deriveOptions(List<AuditLogRow> rows) {
    final users = <String>{};
    final actions = <String>{};
    final resources = <String>{};
    final statuses = <String>{};

    for (final r in rows) {
      final u = r.user.trim();
      if (u.isNotEmpty) users.add(u);
      final a = r.action.trim();
      if (a.isNotEmpty) actions.add(a);
      final re = r.resource.trim();
      if (re.isNotEmpty) resources.add(re);
      final st = r.status.trim();
      if (st.isNotEmpty) statuses.add(st);
    }

    _userOptions = _sorted(users);
    _actionOptions = _sorted(actions);
    _resourceOptions = _sorted(resources);
    _statusOptions = _sorted(statuses);
  }
}

String? _normalize(String? v) {
  final t = v?.trim();
  if (t == null) return null;
  return t.isEmpty ? null : t;
}

List<String> _sorted(Set<String> values) {
  final list = values.toList(growable: false);
  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

