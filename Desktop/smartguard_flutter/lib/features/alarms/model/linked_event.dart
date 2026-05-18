import 'dart:convert';

import 'device.dart';

class LinkedEvent {
  int? id;
  int? deviceId;
  Device? device;
  int? personId;
  dynamic person;
  int? faceId;
  String? image;
  DateTime? timestamp;
  String? embedding;

  LinkedEvent({
    this.id,
    this.deviceId,
    this.device,
    this.personId,
    this.person,
    this.faceId,
    this.image,
    this.timestamp,
    this.embedding,
  });

  factory LinkedEvent.fromMap(Map<String, dynamic> data) => LinkedEvent(
    id: data['id'] as int?,
    deviceId: data['deviceId'] as int?,
    device: data['device'] == null
        ? null
        : Device.fromMap(data['device'] as Map<String, dynamic>),
    personId: data['personId'] as int?,
    person: data['person'] as dynamic,
    faceId: data['faceId'] as int?,
    image: data['image'] as String?,
    timestamp: data['timestamp'] == null
        ? null
        : DateTime.parse(data['timestamp'] as String),
    embedding: data['embedding'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'deviceId': deviceId,
    'device': device?.toMap(),
    'personId': personId,
    'person': person,
    'faceId': faceId,
    'image': image,
    'timestamp': timestamp?.toIso8601String(),
    'embedding': embedding,
  };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [LinkedEvent].
  factory LinkedEvent.fromJson(String data) {
    return LinkedEvent.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [LinkedEvent] to a JSON string.
  String toJson() => json.encode(toMap());
}
