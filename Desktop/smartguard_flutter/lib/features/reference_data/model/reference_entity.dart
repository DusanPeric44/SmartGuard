import 'package:flutter/foundation.dart';

/// Describes a backend reference (lookup) table managed by the admin desktop.
/// All of these expose full CRUD on the API (`GET/POST/PUT/DELETE`).
@immutable
class ReferenceEntity {
  const ReferenceEntity({
    required this.id,
    required this.title,
    required this.singular,
    required this.path,
  });

  /// Stable identifier used for selection.
  final String id;

  /// Plural label shown in the entity selector and table header.
  final String title;

  /// Singular label used in success/confirmation messages.
  final String singular;

  /// API path, e.g. `/AlertTypes`.
  final String path;
}

const List<ReferenceEntity> referenceEntities = <ReferenceEntity>[
  ReferenceEntity(
    id: 'alert-types',
    title: 'Alert Types',
    singular: 'Alert Type',
    path: '/AlertTypes',
  ),
  ReferenceEntity(
    id: 'alert-statuses',
    title: 'Alert Statuses',
    singular: 'Alert Status',
    path: '/AlertStatuses',
  ),
  ReferenceEntity(
    id: 'device-statuses',
    title: 'Device Statuses',
    singular: 'Device Status',
    path: '/DeviceStatuses',
  ),
  ReferenceEntity(
    id: 'recording-types',
    title: 'Recording Types',
    singular: 'Recording Type',
    path: '/RecordingTypes',
  ),
  ReferenceEntity(
    id: 'recording-statuses',
    title: 'Recording Statuses',
    singular: 'Recording Status',
    path: '/RecordingStatuses',
  ),
  ReferenceEntity(
    id: 'report-types',
    title: 'Report Types',
    singular: 'Report Type',
    path: '/ReportTypes',
  ),
  ReferenceEntity(
    id: 'report-statuses',
    title: 'Report Statuses',
    singular: 'Report Status',
    path: '/ReportStatuses',
  ),
];
