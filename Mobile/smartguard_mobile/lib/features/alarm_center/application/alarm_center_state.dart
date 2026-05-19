import 'package:flutter/foundation.dart';

import '../domain/alarm.dart';

enum AlarmCenterStatus { idle, loading, ready, error }

@immutable
class AlarmCenterState {
  const AlarmCenterState({
    required this.status,
    required this.items,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.isLoadingMore,
    required this.actingIds,
    required this.errorMessage,
  });

  const AlarmCenterState.initial()
    : status = AlarmCenterStatus.idle,
      items = const [],
      count = 0,
      page = 1,
      pageSize = 20,
      isLoadingMore = false,
      actingIds = const {},
      errorMessage = null;

  final AlarmCenterStatus status;
  final List<Alarm> items;
  final int count;
  final int page;
  final int pageSize;
  final bool isLoadingMore;
  final Set<int> actingIds;
  final String? errorMessage;

  AlarmCenterState copyWith({
    AlarmCenterStatus? status,
    List<Alarm>? items,
    int? count,
    int? page,
    int? pageSize,
    bool? isLoadingMore,
    Set<int>? actingIds,
    String? errorMessage,
  }) {
    return AlarmCenterState(
      status: status ?? this.status,
      items: items ?? this.items,
      count: count ?? this.count,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      actingIds: actingIds ?? this.actingIds,
      errorMessage: errorMessage,
    );
  }
}
