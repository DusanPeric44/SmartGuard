import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_guard_flutter/features/profile/application/profile_controller.dart';
import 'package:smart_guard_flutter/features/profile/domain/profile_models.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/recording_archive_controller.dart';
import '../../domain/recording.dart';
import 'recording_detail_row.dart';
import 'recording_format.dart';
import 'recording_video_player.dart';
import 'recording_video_unavailable.dart';

class RecordingDetailsSheet extends ConsumerWidget {
  const RecordingDetailsSheet({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingArchiveControllerProvider);
    final controller = ref.read(recordingArchiveControllerProvider.notifier);
    final profileState = ref.watch(profileControllerProvider);
    final role = profileState.profile?.role ?? UserRole.viewer;
    final busy = state.downloadingIds.contains(recording.id);
    final resolvedVideo = _resolveRecordingVideoUrl(recording);
    final accessToken = ref.watch(sessionControllerProvider).tokens?.accessToken;
    final videoHeaders = <String, String>{
      if (accessToken != null && accessToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${accessToken.trim()}',
    };

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
                ? RecordingVideoPlayer(
                    url: resolvedVideo.url!,
                    headers: videoHeaders,
                  )
                : RecordingVideoUnavailable(message: resolvedVideo.message),
          ),
          const SizedBox(height: AppDimens.spaceL),
          RecordingDetailRow(label: 'Device', value: recording.title),
          const SizedBox(height: AppDimens.spaceS),
          RecordingDetailRow(
            label: 'Timestamp',
            value: formatRecordingDate(recording.timestamp),
          ),
          const SizedBox(height: AppDimens.spaceS),
          RecordingDetailRow(label: 'Duration', value: recording.durationLabel),
          const SizedBox(height: AppDimens.spaceS),
          RecordingDetailRow(
            label: 'Type',
            value: recording.typeName.trim().isEmpty
                ? 'Unknown'
                : recording.typeName.trim(),
          ),
          const SizedBox(height: AppDimens.spaceL),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: role == UserRole.viewer
                      ? AppStrings.disabledViewerDownload
                      : (busy ? AppStrings.disabledActionInProgress : ''),
                  child: FilledButton.icon(
                    onPressed: role == UserRole.viewer || busy
                        ? null
                        : () async {
                            await controller.download(recording: recording);
                            final latest = ref.read(
                              recordingArchiveControllerProvider,
                            );
                            if (context.mounted &&
                                latest.errorMessage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download started'),
                                ),
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
