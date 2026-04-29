import 'feature_template_item.dart';

abstract interface class FeatureTemplateRepository {
  Future<List<FeatureTemplateItem>> loadItems();
}

class StubFeatureTemplateRepository implements FeatureTemplateRepository {
  const StubFeatureTemplateRepository();

  @override
  Future<List<FeatureTemplateItem>> loadItems() async {
    return const [];
  }
}

