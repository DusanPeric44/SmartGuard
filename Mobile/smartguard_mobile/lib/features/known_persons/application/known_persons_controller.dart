import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/known_persons_repository.dart';
import 'known_persons_state.dart';

final knownPersonsRepositoryProvider = Provider<KnownPersonsRepository>((ref) {
  return const StubKnownPersonsRepository();
});

final knownPersonsControllerProvider =
    NotifierProvider<KnownPersonsController, KnownPersonsState>(
      KnownPersonsController.new,
    );

class KnownPersonsController extends Notifier<KnownPersonsState> {
  @override
  KnownPersonsState build() {
    return const KnownPersonsState.idle();
  }

  Future<void> refresh() async {
    state = const KnownPersonsState.loading();
    try {
      final names = await ref
          .read(knownPersonsRepositoryProvider)
          .loadKnownPersonNames();
      state = KnownPersonsState.ready(names);
    } catch (_) {
      state = const KnownPersonsState.error('Neuspješno učitavanje');
    }
  }
}
