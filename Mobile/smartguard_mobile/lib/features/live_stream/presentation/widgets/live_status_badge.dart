import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/live_stream_state.dart';

class LiveStatusBadge extends StatelessWidget {
  const LiveStatusBadge({super.key, required this.status});

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

    final color = switch (status) {
      LiveStreamStatus.playing => Colors.green,
      LiveStreamStatus.buffering => Colors.orange,
      LiveStreamStatus.reconnecting => Colors.orange,
      LiveStreamStatus.connecting => Colors.blue,
      LiveStreamStatus.idle => Colors.grey,
      LiveStreamStatus.error => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        border: Border.all(color: color),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
