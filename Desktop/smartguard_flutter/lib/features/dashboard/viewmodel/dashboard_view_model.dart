import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required DashboardRepository repository})
    : _repo = repository;

  final DashboardRepository _repo;

  DashboardOverview? _overview;
  DashboardOverview? get overview => _overview;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastRefresh;
  DateTime? get lastRefresh => _lastRefresh;

  Timer? _timer;
  int _reqId = 0;

  Future<void> init() async {
    await refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    _reqId++;
    final current = _reqId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.loadOverview().timeout(
        const Duration(seconds: 8),
      );
      if (current != _reqId) return;
      _overview = res;
      _lastRefresh = DateTime.now();
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
}
