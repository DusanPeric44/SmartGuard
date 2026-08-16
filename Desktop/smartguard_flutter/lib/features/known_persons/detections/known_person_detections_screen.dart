import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/widgets/authenticated_network_image.dart';
import 'package:smartguard_flutter/features/known_persons/detections/data/api_known_person_detections_repository.dart';
import 'package:smartguard_flutter/features/known_persons/detections/data/known_person_detections_repository.dart';
import 'package:smartguard_flutter/features/known_persons/detections/model/known_person_detection_image.dart';
import 'package:smartguard_flutter/features/known_persons/detections/viewmodel/known_person_detections_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class KnownPersonDetectionsScreen extends StatefulWidget {
  const KnownPersonDetectionsScreen({
    super.key,
    required this.personId,
    this.personName,
  });

  final String personId;
  final String? personName;

  @override
  State<KnownPersonDetectionsScreen> createState() =>
      _KnownPersonDetectionsScreenState();
}

class _KnownPersonDetectionsScreenState extends State<KnownPersonDetectionsScreen> {
  KnownPersonDetectionsRepository? _repo;
  KnownPersonDetectionsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiKnownPersonDetectionsRepository(api: AppScope.of(context).api);
    _vm = KnownPersonDetectionsViewModel(
      repository: _repo!,
      personId: widget.personId,
    );
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Center(child: AsyncStatePanel.loading());

    final title = (widget.personName ?? '').trim().isEmpty
        ? 'Detections: ${widget.personId}'
        : 'Detections: ${widget.personName}';

    return Column(
      children: [
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.go('/known-persons'),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: vm.isLoading ? null : vm.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm)),
      ],
    );
  }

  Widget _buildBody(KnownPersonDetectionsViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No detections for this person.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1200
                  ? 5
                  : width >= 900
                  ? 4
                  : width >= 600
                  ? 3
                  : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: vm.items.length,
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  return _DetectionImageTile(
                    image: item,
                    onTap: () => _openPreview(item),
                  );
                },
              );
            },
          ),
        ),
        if (vm.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: vm.isLoading ? null : vm.loadMore,
                child: vm.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load more'),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openPreview(KnownPersonDetectionImage item) async {
    final url = item.image;
    final timestamp = item.timestamp?.toString() ?? '';
    final score = item.score?.toStringAsFixed(3) ?? '';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          timestamp.isEmpty ? 'Preview' : timestamp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (score.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Score: $score',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        child: AuthenticatedNetworkImage(
                          url: url,
                          fit: BoxFit.contain,
                          errorWidget: const Center(child: Text('Failed to load.')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetectionImageTile extends StatelessWidget {
  const _DetectionImageTile({required this.image, required this.onTap});

  final KnownPersonDetectionImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ts = image.timestamp?.toString() ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: AuthenticatedNetworkImage(
                url: image.image,
                fit: BoxFit.cover,
                errorWidget: const Center(child: Text('No image')),
              ),
            ),
            if (ts.isNotEmpty)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ts,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

