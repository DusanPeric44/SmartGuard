import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../recording_archive/domain/recording.dart';

class DeviceRecordingRow extends StatelessWidget {
  const DeviceRecordingRow({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: ListTile(
        leading: const Icon(Icons.movie_outlined),
        title: Text(
          recording.title.trim().isEmpty ? 'Recording' : recording.title,
        ),
        subtitle: Text(
          recording.typeName.trim().isEmpty
              ? recording.durationLabel
              : '${recording.typeName.trim()} · ${recording.durationLabel}',
        ),
      ),
    );
  }
}
