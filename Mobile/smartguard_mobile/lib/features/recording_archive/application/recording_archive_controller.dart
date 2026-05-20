import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/ui_error_mapper.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/downloads/archive_downloader.dart';
import '../domain/recording_archive_repository.dart';
import '../domain/recording.dart';
import 'recording_archive_state.dart';

final recordingArchiveRepositoryProvider = Provider<RecordingArchiveRepository>(
  (ref) {
    return ApiRecordingArchiveRepository(ref.read(dioProvider));
  },
);

final recordingArchiveControllerProvider =
    NotifierProvider<RecordingArchiveController, RecordingArchiveState>(
      RecordingArchiveController.new,
    );

class RecordingArchiveController extends Notifier<RecordingArchiveState> {
  final _errorMapper = const UiErrorMapper();

  @override
  RecordingArchiveState build() {
    return const RecordingArchiveState.initial();
  }

  Future<void> loadInitial() async {
    if (state.status != RecordingArchiveStatus.idle) return;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(
        status: RecordingArchiveStatus.loading,
        page: 1,
        isLoadingMore: false,
        downloadingIds: const {},
        errorMessage: null,
      );

      final response = await ref
          .read(recordingArchiveRepositoryProvider)
          .search(page: 1, pageSize: state.pageSize);

      state = state.copyWith(
        status: RecordingArchiveStatus.ready,
        items: response.result,
        count: response.count,
        page: 1,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecordingArchiveStatus.error,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != RecordingArchiveStatus.ready) return;
    if (state.isLoadingMore) return;
    if (state.count != 0 && state.items.length >= state.count) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final response = await ref
          .read(recordingArchiveRepositoryProvider)
          .search(page: nextPage, pageSize: state.pageSize);

      state = state.copyWith(
        items: [...state.items, ...response.result],
        count: response.count,
        page: nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _mapMessage(e),
      );
    }
  }

  Future<void> download({required Recording recording}) async {
    final fileName = recording.fileName;
    if (fileName == null || fileName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Missing recording file name');
      return;
    }

    if (state.downloadingIds.contains(recording.id)) return;
    state = state.copyWith(
      downloadingIds: {...state.downloadingIds, recording.id},
      errorMessage: null,
    );

    final base = AppConfig.archiveBaseUrl.replaceAll(RegExp(r'/*$'), '');
    final encoded = Uri.encodeComponent(fileName);
    final url = '$base/api/VideoArchive/download/$encoded';
    final accessToken = ref.read(sessionControllerProvider).tokens?.accessToken;
    final headers = <String, String>{
      if (accessToken != null && accessToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${accessToken.trim()}',
    };

    try {
      await ref
          .read(archiveDownloaderProvider)
          .downloadToDownloads(
            url: url,
            fileName: fileName,
            headers: headers.isEmpty ? null : headers,
          );
    } catch (e) {
      state = state.copyWith(errorMessage: _mapMessage(e));
    } finally {
      state = state.copyWith(
        downloadingIds: {...state.downloadingIds}..remove(recording.id),
      );
    }
  }

  String _mapMessage(Object error) {
    if (error is ApiError) {
      return _errorMapper.fromApiError(error).message;
    }
    return AppStrings.errorUnknown;
  }
}
