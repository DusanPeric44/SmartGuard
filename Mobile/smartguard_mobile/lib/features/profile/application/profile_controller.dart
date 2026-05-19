import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
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
    return const ProfileState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);
    try {
      final profile = await ref.read(profileRepositoryProvider).getMe();
      state = state.copyWith(
        status: ProfileStatus.ready,
        profile: profile,
        fullName: profile.fullName,
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
      fullName: profile.fullName,
      email: profile.email,
      errorMessage: null,
    );
  }

  void cancelEditing() {
    final profile = state.profile;
    state = state.copyWith(
      status: ProfileStatus.ready,
      fullName: profile?.fullName ?? '',
      email: profile?.email ?? '',
      errorMessage: null,
    );
  }

  void setFullName(String value) {
    state = state.copyWith(fullName: value, errorMessage: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  Future<void> saveProfile() async {
    if (!state.canSave) return;
    state = state.copyWith(status: ProfileStatus.saving, errorMessage: null);
    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            UpdateProfileRequest(
              fullName: state.fullName.trim(),
              email: state.email.trim(),
            ),
          );
      state = state.copyWith(
        status: ProfileStatus.ready,
        profile: updated,
        fullName: updated.fullName,
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
    return ref.read(sessionControllerProvider.notifier).logout();
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
