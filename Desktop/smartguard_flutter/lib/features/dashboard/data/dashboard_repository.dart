import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardOverview> loadOverview();
}
