import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';

class LiveRecordButton extends StatelessWidget {
  const LiveRecordButton({
    super.key,
    required this.isRecording,
    required this.isBusy,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final label = isRecording
        ? AppStrings.liveStreamStop
        : AppStrings.liveStreamRecord;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: isBusy ? null : (isRecording ? onStop : onStart),
          backgroundColor: isRecording ? Colors.red : null,
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
        ),
        const SizedBox(height: AppDimens.spaceS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceM,
            vertical: AppDimens.spaceS,
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
