import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/config/app_config.dart';
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
    final busy = state.downloadingIds.contains(recording.id);
    final resolvedVideo = _resolveRecordingVideoUrl(recording);

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
            child: resolvedVideo.url != null
                ? _RecordingVideoPlayer(url: resolvedVideo.url!)
                : _VideoUnavailable(message: resolvedVideo.message),
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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          await controller.download(recording: recording);
                          final latest = ref.read(
                            recordingArchiveControllerProvider,
                          );
                          if (context.mounted && latest.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Download started')),
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

({Uri? url, String message}) _resolveRecordingVideoUrl(Recording recording) {
  final raw = recording.filePath?.trim();
  if (raw == null || raw.isEmpty) {
    return (url: null, message: 'Video unavailable');
  }

  if (raw.toLowerCase().startsWith('uploading:')) {
    return (url: null, message: 'Video is still processing');
  }

  Uri? parsed;
  try {
    parsed = Uri.parse(raw);
  } catch (_) {}

  if (parsed != null && parsed.hasScheme) {
    return (url: parsed, message: '');
  }

  final base = Uri.parse(AppConfig.archiveBaseUrl);
  final path = raw.startsWith('/') ? raw.substring(1) : raw;
  return (url: base.resolve(path), message: '');
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.spaceM),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _RecordingVideoPlayer extends StatefulWidget {
  const _RecordingVideoPlayer({required this.url});

  final Uri url;

  @override
  State<_RecordingVideoPlayer> createState() => _RecordingVideoPlayerState();
}

class _RecordingVideoPlayerState extends State<_RecordingVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  Object? _initializeError;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _RecordingVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initController();
    }
  }

  void _initController() {
    final controller = VideoPlayerController.networkUrl(widget.url);
    controller.addListener(_onControllerChanged);
    final future = controller.initialize();
    setState(() {
      _controller = controller;
      _initializeFuture = future;
      _initializeError = null;
    });

    future.catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _initializeError = e;
      });
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_onControllerChanged);
    controller.pause();
    controller.dispose();
    _controller = null;
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final init = _initializeFuture;

    if (_initializeError != null) {
      return Container(
        width: double.infinity,
        height: 180,
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: const Text('Failed to load video'),
      );
    }

    if (controller == null || init == null) {
      return const SizedBox(height: 180);
    }

    return FutureBuilder<void>(
      future: init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return Container(
            width: double.infinity,
            height: 180,
            color: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final aspect = controller.value.aspectRatio.isFinite &&
                controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9;

        final position = controller.value.position;
        final duration = controller.value.duration;

        return AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlay,
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceM,
                    vertical: AppDimens.spaceS,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spaceS),
                      Row(
                        children: [
                          Text(
                            _formatPlaybackTime(position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            _formatPlaybackTime(duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatPlaybackTime(Duration d) {
  final total = d.inSeconds;
  if (total <= 0) return '00:00';

  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;

  String two(int v) => v.toString().padLeft(2, '0');

  if (hours > 0) {
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
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
