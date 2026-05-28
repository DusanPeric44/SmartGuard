import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'notification_item.dart';
import 'notifications_repository.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._dio);

  final Dio _dio;

  @override
  Future<int> getUnreadCount() async {
    final response = await _dio.get<Object?>(
      ApiPaths.notifications,
      queryParameters: const {
        'isRead': false,
        'page': 1,
        'pageSize': 1,
      },
    );

    final data = response.data;
    if (data is! Map) return 0;
    final raw = data['count'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  Future<List<NotificationItem>> getLatest({int pageSize = 10}) async {
    final response = await _dio.get<Object?>(
      ApiPaths.notifications,
      queryParameters: {
        'page': 1,
        'pageSize': pageSize,
      },
    );

    final data = response.data;
    if (data is! Map) return const [];
    final result = data['result'];
    if (result is! List) return const [];

    return result
        .whereType<Map>()
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead(int id) async {
    await _dio.patch<void>(ApiPaths.notificationRead(id));
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _dio.post<Object?>(ApiPaths.notificationsReadAll);
    final data = response.data;
    if (data is! Map) return 0;
    final raw = data['marked'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

