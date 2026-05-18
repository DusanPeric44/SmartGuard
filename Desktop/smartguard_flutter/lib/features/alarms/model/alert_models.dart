import 'dart:convert';

import 'alert_status.dart';
import 'alert_type.dart';
import 'device.dart';
import 'linked_event.dart';

class AlertRow {
  int? id;
  int? typeId;
  AlertType? alertType;
  int? statusId;
  AlertStatus? alertStatus;
  String? description;
  int? deviceId;
  Device? device;
  int? linkedEventId;
  LinkedEvent? linkedEvent;
  dynamic confirmedByUserId;
  bool? isDeleted;

  AlertRow({
    this.id,
    this.typeId,
    this.alertType,
    this.statusId,
    this.alertStatus,
    this.description,
    this.deviceId,
    this.device,
    this.linkedEventId,
    this.linkedEvent,
    this.confirmedByUserId,
    this.isDeleted,
  });

  factory AlertRow.fromMap(Map<String, dynamic> data) => AlertRow(
    id: data['id'] as int?,
    typeId: data['typeId'] as int?,
    alertType: data['alertType'] == null
        ? null
        : AlertType.fromMap(data['alertType'] as Map<String, dynamic>),
    statusId: data['statusId'] as int?,
    alertStatus: data['alertStatus'] == null
        ? null
        : AlertStatus.fromMap(data['alertStatus'] as Map<String, dynamic>),
    description: data['description'] as String?,
    deviceId: data['deviceId'] as int?,
    device: data['device'] == null
        ? null
        : Device.fromMap(data['device'] as Map<String, dynamic>),
    linkedEventId: data['linkedEventId'] as int?,
    linkedEvent: data['linkedEvent'] == null
        ? null
        : LinkedEvent.fromMap(data['linkedEvent'] as Map<String, dynamic>),
    confirmedByUserId: data['confirmedByUserId'] as dynamic,
    isDeleted: data['isDeleted'] as bool?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'typeId': typeId,
    'alertType': alertType?.toMap(),
    'statusId': statusId,
    'alertStatus': alertStatus?.toMap(),
    'description': description,
    'deviceId': deviceId,
    'device': device?.toMap(),
    'linkedEventId': linkedEventId,
    'linkedEvent': linkedEvent?.toMap(),
    'confirmedByUserId': confirmedByUserId,
    'isDeleted': isDeleted,
  };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [AlertRow].
  factory AlertRow.fromJson(Map<String, dynamic> data) {
    return AlertRow.fromMap(data);
  }

  /// `dart:convert`
  ///
  /// Converts [AlertRow] to a JSON string.
  String toJson() => json.encode(toMap());
}
