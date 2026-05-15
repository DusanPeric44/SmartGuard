import 'dart:math';

import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';

class StubDashboardRepository implements DashboardRepository {
  StubDashboardRepository({int seed = 5}) : _rng = Random(seed);

  final Random _rng;

  @override
  Future<DashboardKpis> loadKpis() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final online = 18 + _rng.nextInt(10);
    final offline = _rng.nextInt(6);
    final alarms = _rng.nextInt(8);
    final rec = 60 + _rng.nextInt(120);
    final total = 1024 + _rng.nextInt(2048);
    final used = 400 + _rng.nextInt(total - 200);
    return DashboardKpis(
      devicesOnline: online,
      devicesOffline: offline,
      activeAlarms: alarms,
      recordingsLast24h: rec,
      storageUsedGb: used,
      storageTotalGb: total,
    );
  }

  @override
  Future<List<DashboardAlert>> loadRecentAlerts() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final now = DateTime.now();
    return List.generate(6, (i) {
      final severity = (i % 3 == 0) ? 'HIGH' : (i % 3 == 1 ? 'MED' : 'LOW');
      return DashboardAlert(
        id: 'a-${i + 1}',
        title: 'Alarm $severity on Camera ${(i + 1).toString().padLeft(2, '0')}',
        severity: severity,
        timestamp: now.subtract(Duration(minutes: 6 * (i + 1))),
      );
    });
  }
}

