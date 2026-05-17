import 'package:flutter/foundation.dart';

import '../domain/user_notification_preference.dart';

enum KnownPersonsStatus { idle, loading, ready, error }

@immutable
class KnownPersonsState {
  const KnownPersonsState({
    required this.status,
    required this.items,
    required this.count,
    required this.updatingPersonIds,
    required this.errorMessage,
  });

  const KnownPersonsState.initial()
    : status = KnownPersonsStatus.idle,
      items = const [],
      count = 0,
      updatingPersonIds = const {},
      errorMessage = null;

  final KnownPersonsStatus status;
  final List<UserNotificationPreference> items;
  final int count;
  final Set<String> updatingPersonIds;
  final String? errorMessage;

  KnownPersonsState copyWith({
    KnownPersonsStatus? status,
    List<UserNotificationPreference>? items,
    int? count,
    Set<String>? updatingPersonIds,
    String? errorMessage,
  }) {
    return KnownPersonsState(
      status: status ?? this.status,
      items: items ?? this.items,
      count: count ?? this.count,
      updatingPersonIds: updatingPersonIds ?? this.updatingPersonIds,
      errorMessage: errorMessage,
    );
  }
}
