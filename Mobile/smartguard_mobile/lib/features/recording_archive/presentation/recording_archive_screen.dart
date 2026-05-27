import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_guard_flutter/features/profile/application/profile_controller.dart';
import 'package:smart_guard_flutter/features/profile/domain/profile_models.dart';

import '../../../core/constants/app_dimens.dart';
import '../application/recording_archive_controller.dart';
import '../application/recording_archive_state.dart';
import '../domain/recording.dart';

class RecordingArchiveScreen extends ConsumerStatefulWidget {
  const RecordingArchiveScreen({super.key});

  @override
  ConsumerState<RecordingArchiveScreen> createState() =>
      _RecordingArchiveScreenState();
}

class _RecordingArchiveScreenState
    extends ConsumerState<RecordingArchiveScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    final threshold = position.maxScrollExtent - 200;
    if (position.pixels >= threshold) {
      ref.read(recordingArchiveControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingArchiveControllerProvider);
    final controller = ref.read(recordingArchiveControllerProvider.notifier);

    if (state.status == RecordingArchiveStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadInitial();
      });
    }

    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);

    return SafeArea(
      child: Column(
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.spaceM,
                AppDimens.spaceM,
                AppDimens.spaceM,
                0,
              ),
              child: _ErrorBanner(message: state.errorMessage!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: AppDimens.pagePadding,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final recording = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.spaceM),
                    child: _RecordingCard(
                      recording: recording,
                      onTap: () => _showDetails(context, recording),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, Recording recording) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RecordingDetailsSheet(recording: recording),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.recording, required this.onTap});

  final Recording recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppDimens.cardRadius,
      elevation: 1,
      child: InkWell(
        borderRadius: AppDimens.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spaceM),
          child: Row(
            children: [
              _Thumbnail(durationLabel: recording.durationLabel),
              const SizedBox(width: AppDimens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.spaceS),
                    Text(
                      _formatDate(recording.timestamp),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimens.spaceS),
                    _TypeChip(typeName: recording.typeName),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.durationLabel});

  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/video-thumbnail.png',
            width: 92,
            height: 72,
            fit: BoxFit.cover,
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                durationLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) {
    final label = typeName.trim().isEmpty ? 'Unknown' : typeName.trim();
    final normalized = label.toLowerCase();

    final (fg, bg) = normalized.contains('face')
        ? (Colors.green.shade700, Colors.green.shade50)
        : (Colors.amber.shade900, Colors.amber.shade50);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class _RecordingDetailsSheet extends ConsumerWidget {
  const _RecordingDetailsSheet({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingArchiveControllerProvider);
    final controller = ref.read(recordingArchiveControllerProvider.notifier);
    final profileState = ref.watch(profileControllerProvider);
    final role = profileState.profile?.role ?? UserRole.viewer;
    final busy = state.downloadingIds.contains(recording.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spaceL,
        0,
        AppDimens.spaceL,
        AppDimens.spaceL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recording Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceM),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/video-thumbnail.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceL),
          _DetailRow(label: 'Device', value: recording.title),
          const SizedBox(height: AppDimens.spaceS),
          _DetailRow(
            label: 'Timestamp',
            value: _formatDate(recording.timestamp),
          ),
          const SizedBox(height: AppDimens.spaceS),
          _DetailRow(label: 'Duration', value: recording.durationLabel),
          const SizedBox(height: AppDimens.spaceS),
          _DetailRow(
            label: 'Type',
            value: recording.typeName.trim().isEmpty
                ? 'Unknown'
                : recording.typeName.trim(),
          ),
          const SizedBox(height: AppDimens.spaceL),
          if (role != UserRole.viewer)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: role == UserRole.viewer || busy
                        ? null
                        : () async {
                            await controller.download(recording: recording);
                            final latest = ref.read(
                              recordingArchiveControllerProvider,
                            );
                            if (context.mounted &&
                                latest.errorMessage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download started'),
                                ),
                              );
                            }
                          },
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[d.month - 1];
  final day = d.day.toString().padLeft(2, '0');
  final year = d.year.toString();

  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final hour = hour12.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  return '$month $day, $year $hour:$minute $ampm';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: AppDimens.cardRadius,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
