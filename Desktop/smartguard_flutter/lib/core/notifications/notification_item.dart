class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  final int id;
  final String userId;
  final String title;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  static NotificationItem fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['userId'];
    final title = json['title'];
    final text = json['text'];
    final timestamp = json['timestamp'];
    final isRead = json['isRead'];

    return NotificationItem(
      id: id is int ? id : int.parse(id.toString()),
      userId: userId?.toString() ?? '',
      title: title?.toString() ?? '',
      text: text?.toString() ?? '',
      timestamp: timestamp is String ? DateTime.parse(timestamp) : DateTime(1970),
      isRead: isRead is bool ? isRead : (isRead?.toString().toLowerCase() == 'true'),
    );
  }
}

