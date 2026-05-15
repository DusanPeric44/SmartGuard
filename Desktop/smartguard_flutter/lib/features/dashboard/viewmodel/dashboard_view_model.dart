import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required DashboardRepository repository}) : _repo = repository;

  final DashboardRepository _repo;

  DashboardKpis? _kpis;
  DashboardKpis? get kpis => _kpis;

  List<DashboardAlert> _alerts = const [];
  List<DashboardAlert> get alerts => _alerts;

  bool _loadingKpis = false;
  bool get loadingKpis => _loadingKpis;

  bool _loadingAlerts = false;
  bool get loadingAlerts => _loadingAlerts;

  String? _kpisError;
  String? get kpisError => _kpisError;

  String? _alertsError;
  String? get alertsError => _alertsError;

  DateTime? _lastRefresh;
  DateTime? get lastRefresh => _lastRefresh;

  bool _autoRefresh = false;
  bool get autoRefresh => _autoRefresh;

  Duration _interval = const Duration(seconds: 30);
  Duration get interval => _interval;

  Timer? _timer;

  Future<void> init() async {
    await refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadKpis(),
      _loadAlerts(),
    ]);
    _lastRefresh = DateTime.now();
    notifyListeners();
  }

  Future<void> _loadKpis() async {
    _loadingKpis = true;
    _kpisError = null;
    notifyListeners();
    try {
      _kpis = await _repo.loadKpis().timeout(const Duration(seconds: 6));
    } catch (e) {
      _kpisError = UiErrorMapper.toMessage(e);
    } finally {
      _loadingKpis = false;
      notifyListeners();
    }
  }

  Future<void> _loadAlerts() async {
    _loadingAlerts = true;
    _alertsError = null;
    notifyListeners();
    try {
      _alerts = await _repo.loadRecentAlerts().timeout(const Duration(seconds: 6));
    } catch (e) {
      _alertsError = UiErrorMapper.toMessage(e);
    } finally {
      _loadingAlerts = false;
      notifyListeners();
    }
  }

  void setAutoRefresh(bool value) {
    _autoRefresh = value;
    _timer?.cancel();
    if (value) {
      _timer = Timer.periodic(_interval, (_) {
        refresh();
      });
    }
    notifyListeners();
  }

  void setInterval(Duration interval) {
    _interval = interval;
    if (_autoRefresh) {
      setAutoRefresh(true);
    } else {
      notifyListeners();
    }
  }
}

