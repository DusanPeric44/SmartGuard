import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_repository.dart';
import 'profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const StubProfileRepository();
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState.idle();
  }

  Future<void> refresh() async {
    state = const ProfileState.loading();
    try {
      final name = await ref.read(profileRepositoryProvider).loadDisplayName();
      state = ProfileState.ready(name);
    } catch (_) {
      state = const ProfileState.error('Neuspješno učitavanje profila');
    }
  }
}
