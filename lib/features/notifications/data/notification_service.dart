import '../../../core/network/api_client.dart';
import 'notification_models.dart';

class NotificationService {
  NotificationService({required this.token, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final String token;
  final ApiClient _apiClient;

  Future<NotificationList> fetchNotifications({
    String? type,
    bool unreadOnly = false,
  }) async {
    final path = Uri(
      path: '/mobile/notifications',
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (unreadOnly) 'unread': '1',
      },
    ).toString();
    final data = await _apiClient.get(path);
    return NotificationList.fromJson(data);
  }

  Future<int> fetchUnreadCount() async {
    final data = await _apiClient.get('/mobile/notifications/unread-count');
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _apiClient.post('/mobile/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _apiClient.post('/mobile/notifications/read-all');
  }

  /// Đồng bộ mã WebPush Subscription lên Server Laravel để nhận thông báo khi tắt app
  Future<bool> registerPushSubscription(Map<String, dynamic> subscription) async {
    try {
      await _apiClient.post(
        '/mobile/push-subscriptions',
        body: subscription,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
