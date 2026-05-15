import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../application/live_stream_controller.dart';
import '../application/live_stream_state.dart';

class LiveStreamFullscreenScreen extends ConsumerWidget {
  const LiveStreamFullscreenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveStreamControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (state.latestFrameBytes != null)
              Image.memory(
                state.latestFrameBytes!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              )
            else
              const Center(
                child: Text(
                  AppStrings.liveStreamNoFrames,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Positioned(
              left: AppDimens.spaceM,
              top: AppDimens.spaceM,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              right: AppDimens.spaceM,
              top: AppDimens.spaceM,
              child: _StatusText(status: state.status),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.status});

  final LiveStreamStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      LiveStreamStatus.idle => AppStrings.statusIdle,
      LiveStreamStatus.connecting => AppStrings.statusConnecting,
      LiveStreamStatus.playing => AppStrings.statusPlaying,
      LiveStreamStatus.buffering => AppStrings.statusBuffering,
      LiveStreamStatus.reconnecting => AppStrings.statusReconnecting,
      LiveStreamStatus.error => AppStrings.statusError,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
