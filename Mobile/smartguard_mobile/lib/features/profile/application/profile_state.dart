import 'package:flutter/foundation.dart';

import '../domain/profile_models.dart';

enum ProfileStatus { idle, loading, ready, editing, saving, error }

@immutable
class ProfileState {
  const ProfileState({
    required this.status,
    required this.profile,
    required this.fullName,
    required this.email,
    required this.errorMessage,
  });

  const ProfileState.initial()
    : status = ProfileStatus.idle,
      profile = null,
      fullName = '',
      email = '',
      errorMessage = null;

  final ProfileStatus status;
  final UserProfile? profile;
  final String fullName;
  final String email;
  final String? errorMessage;

  bool get isLoading => status == ProfileStatus.loading;
  bool get isSaving => status == ProfileStatus.saving;
  bool get isEditing => status == ProfileStatus.editing;

  bool get canSave => fullName.trim().isNotEmpty && email.trim().isNotEmpty;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? fullName,
    String? email,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }
}
