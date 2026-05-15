import 'package:flutter/foundation.dart';

import '../domain/device.dart';

enum DevicesStatus { idle, loading, ready, error }

@immutable
class DevicesState {
  const DevicesState({
    required this.status,
    required this.devices,
    required this.count,
    required this.selectedDeviceId,
    required this.errorMessage,
  });

  const DevicesState.initial()
    : status = DevicesStatus.idle,
      devices = const [],
      count = 0,
      selectedDeviceId = null,
      errorMessage = null;

  final DevicesStatus status;
  final List<Device> devices;
  final int count;
  final String? selectedDeviceId;
  final String? errorMessage;

  Device? get selectedDevice {
    final id = selectedDeviceId;
    if (id == null) return null;
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  DevicesState copyWith({
    DevicesStatus? status,
    List<Device>? devices,
    int? count,
    String? selectedDeviceId,
    String? errorMessage,
  }) {
    return DevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      count: count ?? this.count,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
      errorMessage: errorMessage,
    );
  }
}
