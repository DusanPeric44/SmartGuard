import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_dimens.dart';

class RecordingVideoPlayer extends StatefulWidget {
  const RecordingVideoPlayer({super.key, required this.url});

  final Uri url;

  @override
  State<RecordingVideoPlayer> createState() => _RecordingVideoPlayerState();
}

class _RecordingVideoPlayerState extends State<RecordingVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  Object? _initializeError;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant RecordingVideoPlayer oldWidget) {
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

        final aspect =
            controller.value.aspectRatio.isFinite &&
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
