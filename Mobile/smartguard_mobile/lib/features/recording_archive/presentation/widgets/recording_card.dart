import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../domain/recording.dart';
import 'recording_format.dart';
import 'recording_thumbnail.dart';
import 'recording_type_chip.dart';

class RecordingCard extends StatelessWidget {
  const RecordingCard({super.key, required this.recording, required this.onTap});

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
              RecordingThumbnail(durationLabel: recording.durationLabel),
              const SizedBox(width: AppDimens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatRecordingDate(recording.timestamp),
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.spaceS),
                    RecordingTypeChip(typeName: recording.typeName),
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
