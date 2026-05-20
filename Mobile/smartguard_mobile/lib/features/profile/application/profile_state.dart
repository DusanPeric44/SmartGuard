import 'package:flutter/foundation.dart';

import '../domain/profile_models.dart';

enum ProfileStatus { idle, loading, ready, editing, saving, error }

@immutable
class ProfileState {
  const ProfileState({
    required this.status,
    required this.profile,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.errorMessage,
  });

  const ProfileState.initial()
    : status = ProfileStatus.idle,
      profile = null,
      firstName = '',
      lastName = '',
      email = '',
      errorMessage = null;

  final ProfileStatus status;
  final UserProfile? profile;
  final String firstName;
  final String lastName;
  final String email;
  final String? errorMessage;

  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return '';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  bool get isLoading => status == ProfileStatus.loading;
  bool get isSaving => status == ProfileStatus.saving;
  bool get isEditing => status == ProfileStatus.editing;

  bool get canSave =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? firstName,
    String? lastName,
    String? email,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }
}
