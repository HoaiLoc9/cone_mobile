class NotificationList {
  const NotificationList({
    required this.unreadCount,
    required this.items,
  });

  final int unreadCount;
  final List<AppNotification> items;

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return NotificationList(
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
      items: items.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.meta,
    required this.isRead,
    required this.createdAt,
    required this.badgeColor,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> meta;
  final bool isRead;
  final DateTime? createdAt;
  final String badgeColor;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      meta: json['meta'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] == true,
      createdAt: _parseDate(json['created_at']),
      badgeColor: json['badge_color']?.toString() ?? '',
    );
  }
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}
