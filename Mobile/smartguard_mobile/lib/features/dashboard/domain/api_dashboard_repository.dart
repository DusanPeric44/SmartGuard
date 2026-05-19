import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'dashboard_mobile_response.dart';
import 'dashboard_repository.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<DashboardMobileResponse> loadMobileDashboard() async {
    final response = await _dio.get<Object?>(ApiPaths.dashboardMobile);
    return DashboardMobileResponse.fromJson(response.data);
  }
}

