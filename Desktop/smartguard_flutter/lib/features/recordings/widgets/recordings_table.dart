import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recording_status_chip.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_format.dart';

class RecordingsTable extends StatelessWidget {
  const RecordingsTable({
    super.key,
    required this.rows,
    required this.rowBusy,
    required this.canDownload,
    required this.canSoftDelete,
    required this.onDownload,
    required this.onSoftDelete,
  });

  final List<RecordingRow> rows;
  final Map<String, bool> rowBusy;
  final bool canDownload;
  final bool canSoftDelete;
  final ValueChanged<RecordingRow> onDownload;
  final ValueChanged<int> onSoftDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Timestamp')),
          const DataColumn(label: Text('Device')),
          const DataColumn(label: Text('Type')),
          const DataColumn(label: Text('Status')),
          const DataColumn(numeric: true, label: Text('Duration')),
          const DataColumn(numeric: true, label: Text('Size')),
          const DataColumn(label: Text('Actions')),
        ],
        rows: [for (final r in rows) _row(context, r)],
      ),
    );
  }

  DataRow _row(BuildContext context, RecordingRow r) {
    final key = r.id.toString();
    final busy = rowBusy[key] == true;
    final statusChip = RecordingStatusChip(status: r.status);
    final canDownloadNow = canDownload && !busy;
    final canDeleteNow = canSoftDelete && !busy;
    final deviceLabel = r.deviceName.trim().isNotEmpty
        ? r.deviceName
        : 'Device ${r.deviceId}';

    return DataRow(
      cells: [
        DataCell(Text('${recordingDate(r.startedAt)} ${recordingTime(r.startedAt)}')),
        DataCell(Text(deviceLabel)),
        DataCell(Text(_typeLabel(r.type))),
        DataCell(statusChip),
        DataCell(Text(_durationLabel(r.durationSeconds))),
        DataCell(Text(_bytesLabel(r.sizeBytes))),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: canDownload ? 'Download' : 'Nema dozvolu',
                onPressed: canDownloadNow ? () => onDownload(r) : null,
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton(
                tooltip: canSoftDelete ? 'Soft delete' : 'Nema dozvolu',
                onPressed: canDeleteNow ? () => onSoftDelete(r.id) : null,
                icon: const Icon(Icons.delete_outline),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _durationLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m}m ${s}s';
}

String _bytesLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024.0;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024.0;
  return '${gb.toStringAsFixed(2)} GB';
}

String _typeLabel(RecordingType type) {
  switch (type) {
    case RecordingType.motion:
      return 'Motion';
    case RecordingType.manual:
      return 'Manual';
    case RecordingType.faceDetected:
      return 'Face Detected';
  }
}
