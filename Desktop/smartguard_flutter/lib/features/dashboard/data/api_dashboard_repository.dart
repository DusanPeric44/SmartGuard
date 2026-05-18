import 'package:smartguard_flutter/core/network/api_client.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<DashboardOverview> loadOverview() {
    return _api.get<DashboardOverview>(
      '/Dashboard/desktop',
      decode: (json) => DashboardOverview.fromJson(json),
    );
  }
}

