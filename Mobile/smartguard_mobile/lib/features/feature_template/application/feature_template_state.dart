enum FeatureTemplateStatus { idle, loading, ready, error }

class FeatureTemplateState {
  const FeatureTemplateState._({
    required this.status,
    required this.itemTitles,
    required this.message,
  });

  const FeatureTemplateState.idle()
    : this._(status: FeatureTemplateStatus.idle, itemTitles: const [], message: null);

  const FeatureTemplateState.loading()
    : this._(
        status: FeatureTemplateStatus.loading,
        itemTitles: const [],
        message: null,
      );

  const FeatureTemplateState.ready(List<String> itemTitles)
    : this._(status: FeatureTemplateStatus.ready, itemTitles: itemTitles, message: null);

  const FeatureTemplateState.error(String message)
    : this._(status: FeatureTemplateStatus.error, itemTitles: const [], message: message);

  final FeatureTemplateStatus status;
  final List<String> itemTitles;
  final String? message;
}

