import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_error.dart';
import '../domain/device.dart';
import '../domain/devices_repository.dart';
import 'devices_state.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return ApiDevicesRepository(ref.read(dioProvider));
});

final devicesControllerProvider =
    NotifierProvider<DevicesController, DevicesState>(DevicesController.new);

class DevicesController extends Notifier<DevicesState> {
  final _errorMapper = const UiErrorMapper();

  @override
  DevicesState build() {
    return const DevicesState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(status: DevicesStatus.loading, errorMessage: null);
    try {
      final devices = await ref.read(devicesRepositoryProvider).fetchDevices();
      final selected =
          state.selectedDeviceId ?? (devices.isNotEmpty ? devices.first.id : null);
      state = state.copyWith(
        status: DevicesStatus.ready,
        devices: devices,
        selectedDeviceId: selected,
      );
    } catch (e) {
      state = state.copyWith(
        status: DevicesStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  void select(Device device) {
    state = state.copyWith(selectedDeviceId: device.id, errorMessage: null);
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
