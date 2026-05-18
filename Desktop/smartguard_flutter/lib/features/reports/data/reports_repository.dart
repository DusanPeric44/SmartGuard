import 'dart:typed_data';

import 'package:smartguard_flutter/features/reports/model/paged_result.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';

abstract class ReportsRepository {
  Future<PagedResult<ReportRow>> list({
    required int page,
    required int pageSize,
    DateTime? start,
    DateTime? end,
  });

  Future<void> generate({required DateTime start, required DateTime end});

  Future<Uint8List> download({required String path});
}
