import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/auth/session_state.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_error.dart';
import '../domain/api_profile_repository.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';
import 'profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(ref.read(dioProvider));
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  final _errorMapper = const UiErrorMapper();

  @override
  ProfileState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      final prevTokens = previous?.tokens;
      final nextTokens = next.tokens;

      final prevAccess = prevTokens?.accessToken;
      final nextAccess = nextTokens?.accessToken;

      final authChanged = prevAccess != nextAccess;
      final loggedOut =
          previous?.status == SessionStatus.authenticated &&
          next.status != SessionStatus.authenticated;

      if (authChanged || loggedOut) {
        state = const ProfileState.initial();
      }
    });
    return const ProfileState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);
    try {
      final profile = await ref.read(profileRepositoryProvider).getMe();
      state = state.copyWith(
        status: ProfileStatus.ready,
        profile: profile,
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  void startEditing() {
    final profile = state.profile;
    if (profile == null) return;
    state = state.copyWith(
      status: ProfileStatus.editing,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      errorMessage: null,
    );
  }

  void cancelEditing() {
    final profile = state.profile;
    state = state.copyWith(
      status: ProfileStatus.ready,
      firstName: profile?.firstName ?? '',
      lastName: profile?.lastName ?? '',
      email: profile?.email ?? '',
      errorMessage: null,
    );
  }

  void setFirstName(String value) {
    state = state.copyWith(firstName: value, errorMessage: null);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, errorMessage: null);
  }

  Future<void> saveProfile() async {
    if (!state.canSave) return;
    state = state.copyWith(status: ProfileStatus.saving, errorMessage: null);
    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            UpdateProfileRequest(
              firstName: state.firstName.trim(),
              lastName: state.lastName.trim(),
            ),
          );
      state = state.copyWith(
        status: ProfileStatus.ready,
        profile: updated,
        firstName: updated.firstName,
        lastName: updated.lastName,
        email: updated.email,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.editing,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(status: ProfileStatus.saving, errorMessage: null);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            ChangePasswordRequest(
              currentPassword: currentPassword,
              newPassword: newPassword,
            ),
          );
      state = state.copyWith(status: ProfileStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.ready,
        errorMessage: _mapMessage(e),
      );
      rethrow;
    }
  }

  Future<void> logout() {
    state = const ProfileState.initial();
    return ref.read(sessionControllerProvider.notifier).logout();
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
