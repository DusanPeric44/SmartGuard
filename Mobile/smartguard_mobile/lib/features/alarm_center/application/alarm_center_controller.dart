import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/alarm.dart';
import '../domain/alarm_dismiss_request.dart';
import '../domain/alarm_center_repository.dart';
import 'alarm_center_state.dart';

final alarmCenterRepositoryProvider = Provider<AlarmCenterRepository>((ref) {
  return ApiAlarmCenterRepository(ref.read(dioProvider));
});

final alarmCenterControllerProvider =
    NotifierProvider<AlarmCenterController, AlarmCenterState>(
      AlarmCenterController.new,
    );

class AlarmCenterController extends Notifier<AlarmCenterState> {
  final _errorMapper = const UiErrorMapper();

  @override
  AlarmCenterState build() {
    return const AlarmCenterState.initial();
  }

  Future<void> loadInitial() async {
    if (state.status != AlarmCenterStatus.idle) return;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(
        status: AlarmCenterStatus.loading,
        page: 1,
        isLoadingMore: false,
        actingIds: const {},
        errorMessage: null,
      );

      final response = await ref
          .read(alarmCenterRepositoryProvider)
          .search(page: 1, pageSize: state.pageSize);

      state = state.copyWith(
        status: AlarmCenterStatus.ready,
        items: response.result,
        count: response.count,
        page: 1,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AlarmCenterStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != AlarmCenterStatus.ready) return;
    if (state.isLoadingMore) return;
    if (state.count != 0 && state.items.length >= state.count) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final response = await ref
          .read(alarmCenterRepositoryProvider)
          .search(page: nextPage, pageSize: state.pageSize);

      state = state.copyWith(
        items: [...state.items, ...response.result],
        count: response.count,
        page: nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> confirm({required int id}) async {
    if (state.actingIds.contains(id)) return;
    state = state.copyWith(
      actingIds: {...state.actingIds, id},
      errorMessage: null,
    );

    try {
      final updated =
          await ref.read(alarmCenterRepositoryProvider).confirm(id: id);
      state = state.copyWith(
        items: _replaceAlarm(items: state.items, alarm: updated),
        actingIds: _removeActing(id),
      );
    } catch (e) {
      state = state.copyWith(
        actingIds: _removeActing(id),
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> dismiss({required int id, required String dismissalReason}) async {
    if (state.actingIds.contains(id)) return;
    state = state.copyWith(
      actingIds: {...state.actingIds, id},
      errorMessage: null,
    );

    try {
      final updated = await ref.read(alarmCenterRepositoryProvider).dismiss(
        id: id,
        request: AlarmDismissRequest(dismissalReason: dismissalReason),
      );

      state = state.copyWith(
        items: _replaceAlarm(items: state.items, alarm: updated),
        actingIds: _removeActing(id),
      );
    } catch (e) {
      state = state.copyWith(
        actingIds: _removeActing(id),
        errorMessage: _mapMessage(e),
      );
    }
  }

  Set<int> _removeActing(int id) {
    final next = <int>{...state.actingIds}..remove(id);
    return next;
  }

  List<Alarm> _replaceAlarm({required List<Alarm> items, required Alarm alarm}) {
    final out = <Alarm>[];
    for (final item in items) {
      if (item.id == alarm.id) {
        out.add(alarm);
      } else {
        out.add(item);
      }
    }
    return out;
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
