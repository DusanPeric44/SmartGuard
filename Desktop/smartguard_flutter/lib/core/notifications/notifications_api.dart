import 'package:smartguard_flutter/core/network/api_client.dart';

import 'notification_item.dart';

class NotificationsApi {
  const NotificationsApi({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<int> getUnreadCount() async {
    final data = await _api.get<Map<String, dynamic>>(
      _notificationsPath(
        isRead: false,
        page: 1,
        pageSize: 1,
      ),
      decode: _decodeMap,
    );
    final raw = data['count'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<List<NotificationItem>> getLatest({int pageSize = 10}) async {
    final data = await _api.get<Map<String, dynamic>>(
      _notificationsPath(page: 1, pageSize: pageSize),
      decode: _decodeMap,
    );
    final raw = data['result'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> markAsRead(int id) async {
    await _api.request<Object?>(
      method: 'PATCH',
      path: _notificationReadPath(id),
      decode: (_) => null,
    );
  }

  Future<int> markAllAsRead() async {
    final data = await _api.post<Map<String, dynamic>>(
      _notificationsReadAllPath(),
      decode: _decodeMap,
    );
    final raw = data['marked'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String _notificationsPath({
    bool? isRead,
    int? page,
    int? pageSize,
  }) {
    final qp = <String, String>{};
    if (isRead != null) qp['isRead'] = isRead.toString();
    if (page != null) qp['page'] = page.toString();
    if (pageSize != null) qp['pageSize'] = pageSize.toString();
    return Uri(path: '/api/notifications', queryParameters: qp).toString();
  }

  static String _notificationReadPath(int id) {
    return Uri(path: '/api/notifications/$id/read').toString();
  }

  static String _notificationsReadAllPath() {
    return Uri(path: '/api/notifications/read-all').toString();
  }

  static Map<String, dynamic> _decodeMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return <String, dynamic>{};
  }
}

