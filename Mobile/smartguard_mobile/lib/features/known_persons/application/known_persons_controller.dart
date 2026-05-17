import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/known_persons_repository.dart';
import '../domain/user_notification_preference.dart';
import 'known_persons_state.dart';

final knownPersonsRepositoryProvider = Provider<KnownPersonsRepository>((ref) {
  return ApiKnownPersonsRepository(ref.read(dioProvider));
});

final knownPersonsControllerProvider =
    NotifierProvider<KnownPersonsController, KnownPersonsState>(
      KnownPersonsController.new,
    );

class KnownPersonsController extends Notifier<KnownPersonsState> {
  static const int _page = 1;
  static const int _pageSize = 50;

  final _errorMapper = const UiErrorMapper();

  @override
  KnownPersonsState build() {
    return const KnownPersonsState.initial();
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(
        status: KnownPersonsStatus.loading,
        errorMessage: null,
      );

      final response = await ref
          .read(knownPersonsRepositoryProvider)
          .search(page: _page, pageSize: _pageSize);

      state = state.copyWith(
        status: KnownPersonsStatus.ready,
        items: response.result,
        count: response.count,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: KnownPersonsStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> toggleEnabled({
    required String personId,
    required bool enabled,
  }) async {
    if (state.updatingPersonIds.contains(personId)) return;

    final items = _replaceEnabled(
      items: state.items,
      personId: personId,
      enabled: enabled,
    );
    final nextUpdating = <String>{...state.updatingPersonIds, personId};

    state = state.copyWith(
      items: items,
      updatingPersonIds: nextUpdating,
      errorMessage: null,
    );

    try {
      await ref
          .read(knownPersonsRepositoryProvider)
          .setEnabled(personId: personId, enabled: enabled);

      final cleared = <String>{...state.updatingPersonIds}..remove(personId);
      state = state.copyWith(updatingPersonIds: cleared);
    } catch (e) {
      final reverted = _replaceEnabled(
        items: state.items,
        personId: personId,
        enabled: !enabled,
      );
      final cleared = <String>{...state.updatingPersonIds}..remove(personId);

      state = state.copyWith(
        items: reverted,
        updatingPersonIds: cleared,
        errorMessage: _mapMessage(e),
      );
    }
  }

  List<UserNotificationPreference> _replaceEnabled({
    required List<UserNotificationPreference> items,
    required String personId,
    required bool enabled,
  }) {
    final out = <UserNotificationPreference>[];
    for (final item in items) {
      if (item.personId == personId) {
        out.add(item.copyWith(enabled: enabled));
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
