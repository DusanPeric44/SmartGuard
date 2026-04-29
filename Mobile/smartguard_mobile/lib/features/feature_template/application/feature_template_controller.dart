import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feature_template_repository.dart';
import 'feature_template_state.dart';

final featureTemplateRepositoryProvider = Provider<FeatureTemplateRepository>((ref) {
  return const StubFeatureTemplateRepository();
});

final featureTemplateControllerProvider =
    NotifierProvider<FeatureTemplateController, FeatureTemplateState>(
      FeatureTemplateController.new,
    );

class FeatureTemplateController extends Notifier<FeatureTemplateState> {
  @override
  FeatureTemplateState build() {
    return const FeatureTemplateState.idle();
  }

  Future<void> refresh() async {
    state = const FeatureTemplateState.loading();
    try {
      final items =
          await ref.read(featureTemplateRepositoryProvider).loadItems();
      state = FeatureTemplateState.ready(items.map((e) => e.title).toList());
    } catch (_) {
      state = const FeatureTemplateState.error('Neuspješno učitavanje');
    }
  }
}

