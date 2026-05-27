import 'dart:convert';
import 'package:smartguard_flutter/core/extensions/local_date_parsing.dart';
import 'report_status.dart';
import 'report_type.dart';

class ReportRow {
  int id;
  int typeId;
  ReportType reportType;
  int statusId;
  ReportStatus reportStatus;
  DateTime? periodStartUtc;
  DateTime? periodEndUtc;
  DateTime? generatedAtUtc;
  String? generatedByUserId;
  String fileUrl;
  String? error;

  ReportRow({
    required this.id,
    required this.typeId,
    required this.reportType,
    required this.statusId,
    required this.reportStatus,
    this.periodStartUtc,
    this.periodEndUtc,
    this.generatedAtUtc,
    this.generatedByUserId,
    required this.fileUrl,
    this.error,
  });

  factory ReportRow.fromMap(Map<String, dynamic> data) => ReportRow(
    id: data['id'] as int,
    typeId: data['typeId'] as int,
    reportType: ReportType.fromMap(data['reportType'] as Map<String, dynamic>),
    statusId: data['statusId'] as int,
    reportStatus: ReportStatus.fromMap(
      data['reportStatus'] as Map<String, dynamic>,
    ),
    periodStartUtc: (data['periodStartUtc'] as Object?).toLocalDateTime(),
    periodEndUtc: (data['periodEndUtc'] as Object?).toLocalDateTime(),
    generatedAtUtc: (data['generatedAtUtc'] as Object?).toLocalDateTime(),
    generatedByUserId: data['generatedByUserId'] as dynamic,
    fileUrl: data['fileUrl'] as String,
    error: data['error'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'typeId': typeId,
    'reportType': reportType.toMap(),
    'statusId': statusId,
    'reportStatus': reportStatus.toMap(),
    'periodStartUtc': periodStartUtc,
    'periodEndUtc': periodEndUtc,
    'generatedAtUtc': generatedAtUtc?.toIso8601String(),
    'generatedByUserId': generatedByUserId,
    'fileUrl': fileUrl,
    'error': error,
  };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ReportRow].
  factory ReportRow.fromJson(Map<String, dynamic> data) {
    return ReportRow.fromMap(data);
  }

  /// `dart:convert`
  ///
  /// Converts [ReportRow] to a JSON string.
  String toJson() => json.encode(toMap());
}
