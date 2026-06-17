import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';

class RecordingStatusChip extends StatelessWidget {
  const RecordingStatusChip({super.key, required this.status});

  final RecordingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label),
    );
  }
}

String _statusLabel(RecordingStatus status) {
  switch (status) {
    case RecordingStatus.completed:
      return 'Completed';
    case RecordingStatus.pending:
      return 'Pending';
    case RecordingStatus.uploading:
      return 'Uploading';
    case RecordingStatus.failed:
      return 'Failed';
    case RecordingStatus.archived:
      return 'Archived';
  }
}

Color _statusColor(BuildContext context, RecordingStatus status) {
  switch (status) {
    case RecordingStatus.uploading:
      return Colors.blueAccent.shade400;
    case RecordingStatus.completed:
      return Colors.greenAccent.shade400;
    case RecordingStatus.pending:
      return Colors.amberAccent.shade400;
    case RecordingStatus.failed:
      return Theme.of(context).colorScheme.error;
    case RecordingStatus.archived:
      return Colors.blueGrey.shade300;
  }
}
