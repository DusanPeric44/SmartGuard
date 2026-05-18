import 'dart:convert';

class Device {
  int? id;
  String? name;
  String? location;
  String? apiKey;
  dynamic deviceStatus;
  int? sdCapacity;
  int? freeSpace;

  Device({
    this.id,
    this.name,
    this.location,
    this.apiKey,
    this.deviceStatus,
    this.sdCapacity,
    this.freeSpace,
  });

  factory Device.fromMap(Map<String, dynamic> data) => Device(
    id: data['id'] as int?,
    name: data['name'] as String?,
    location: data['location'] as String?,
    apiKey: data['apiKey'] as String?,
    deviceStatus: data['deviceStatus'] as dynamic,
    sdCapacity: data['sdCapacity'] as int?,
    freeSpace: data['freeSpace'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'apiKey': apiKey,
    'deviceStatus': deviceStatus,
    'sdCapacity': sdCapacity,
    'freeSpace': freeSpace,
  };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Device].
  factory Device.fromJson(String data) {
    return Device.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Device] to a JSON string.
  String toJson() => json.encode(toMap());
}
