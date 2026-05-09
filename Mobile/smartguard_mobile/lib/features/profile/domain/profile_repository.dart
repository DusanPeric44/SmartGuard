import 'profile_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getMe();
  Future<UserProfile> updateProfile(UpdateProfileRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
}
