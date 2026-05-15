import 'package:flutter/foundation.dart';

@immutable
class DashboardKpis {
  const DashboardKpis({
    required this.devicesOnline,
    required this.devicesOffline,
    required this.activeAlarms,
    required this.recordingsLast24h,
    required this.storageUsedGb,
    required this.storageTotalGb,
  });

  final int devicesOnline;
  final int devicesOffline;
  final int activeAlarms;
  final int recordingsLast24h;
  final int storageUsedGb;
  final int storageTotalGb;
}

@immutable
class DashboardAlert {
  const DashboardAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String severity;
  final DateTime timestamp;
}

