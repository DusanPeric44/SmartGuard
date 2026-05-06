import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardKpis> loadKpis();
  Future<List<DashboardAlert>> loadRecentAlerts();
}

