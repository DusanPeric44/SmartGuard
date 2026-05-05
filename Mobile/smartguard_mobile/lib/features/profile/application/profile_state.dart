enum ProfileStatus { idle, loading, ready, error }

class ProfileState {
  const ProfileState._({
    required this.status,
    required this.displayName,
    required this.message,
  });

  const ProfileState.idle()
    : this._(status: ProfileStatus.idle, displayName: null, message: null);

  const ProfileState.loading()
    : this._(status: ProfileStatus.loading, displayName: null, message: null);

  const ProfileState.ready(String? displayName)
    : this._(
        status: ProfileStatus.ready,
        displayName: displayName,
        message: null,
      );

  const ProfileState.error(String message)
    : this._(status: ProfileStatus.error, displayName: null, message: message);

  final ProfileStatus status;
  final String? displayName;
  final String? message;
}
