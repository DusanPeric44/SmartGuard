import 'package:flutter/foundation.dart';

import '../domain/recording.dart';

enum RecordingArchiveStatus { idle, loading, ready, error }

@immutable
class RecordingArchiveState {
  const RecordingArchiveState({
    required this.status,
    required this.items,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.isLoadingMore,
    required this.downloadingIds,
    required this.errorMessage,
  });

  const RecordingArchiveState.initial()
    : status = RecordingArchiveStatus.idle,
      items = const [],
      count = 0,
      page = 1,
      pageSize = 20,
      isLoadingMore = false,
      downloadingIds = const {},
      errorMessage = null;

  final RecordingArchiveStatus status;
  final List<Recording> items;
  final int count;
  final int page;
  final int pageSize;
  final bool isLoadingMore;
  final Set<int> downloadingIds;
  final String? errorMessage;

  RecordingArchiveState copyWith({
    RecordingArchiveStatus? status,
    List<Recording>? items,
    int? count,
    int? page,
    int? pageSize,
    bool? isLoadingMore,
    Set<int>? downloadingIds,
    String? errorMessage,
  }) {
    return RecordingArchiveState(
      status: status ?? this.status,
      items: items ?? this.items,
      count: count ?? this.count,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      downloadingIds: downloadingIds ?? this.downloadingIds,
      errorMessage: errorMessage,
    );
  }
}
