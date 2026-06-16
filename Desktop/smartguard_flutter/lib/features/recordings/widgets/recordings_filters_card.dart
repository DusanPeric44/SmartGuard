import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_device_option.dart';
import 'package:smartguard_flutter/features/recordings/model/recording_models.dart';
import 'package:smartguard_flutter/features/recordings/widgets/recordings_format.dart';

class RecordingsFiltersCard extends StatelessWidget {
  const RecordingsFiltersCard({
    super.key,
    required this.searchController,
    required this.devices,
    required this.selectedDeviceId,
    required this.selectedRange,
    required this.selectedType,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onPickRange,
    required this.onDeviceChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final List<RecordingDeviceOption> devices;
  final int? selectedDeviceId;
  final DateTimeRange? selectedRange;
  final RecordingType? selectedType;
  final RecordingStatus? selectedStatus;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final ValueChanged<int?> onDeviceChanged;
  final ValueChanged<RecordingType?> onTypeChanged;
  final ValueChanged<RecordingStatus?> onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 500,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Device ili ID snimka...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 500,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedDeviceId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All devices'),
                  ),
                  for (final d in devices)
                    DropdownMenuItem<int>(
                      value: d.id,
                      child: Text(
                        d.name,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onDeviceChanged,
                decoration: const InputDecoration(labelText: 'Device'),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<RecordingType?>(
                initialValue: selectedType,
                items: const [
                  DropdownMenuItem<RecordingType?>(
                    value: null,
                    child: Text('All types'),
                  ),
                  DropdownMenuItem(
                    value: RecordingType.motion,
                    child: Text('Motion'),
                  ),
                  DropdownMenuItem(
                    value: RecordingType.manual,
                    child: Text('Manual'),
                  ),
                  DropdownMenuItem(
                    value: RecordingType.faceDetected,
                    child: Text('Face Detected'),
                  ),
                ],
                onChanged: onTypeChanged,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<RecordingStatus?>(
                initialValue: selectedStatus,
                items: const [
                  DropdownMenuItem<RecordingStatus?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.uploading,
                    child: Text('Uploading'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.uploading,
                    child: Text('Uploading'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.failed,
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value: RecordingStatus.archived,
                    child: Text('Archived'),
                  ),
                ],
                onChanged: onStatusChanged,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onPickRange,
              icon: const Icon(Icons.date_range),
              label: Text(_rangeLabel(selectedRange) ?? 'Date range'),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: Text('Reset', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }

  String? _rangeLabel(DateTimeRange? range) {
    if (range == null) return null;
    final s = recordingDate(range.start);
    final e = recordingDate(range.end);
    return '$s → $e';
  }
}
