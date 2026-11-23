import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'web_notification_helper.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _scheduledTimers = {};
  bool _isInitialized = false;

  /// Khởi tạo kênh thông báo trên Android & iOS
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[Notification] Người dùng bấm vào thông báo: ${response.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('[Notification] Khởi tạo hệ thống thông báo cục bộ thành công.');
    } catch (e) {
      debugPrint('[Notification] Lỗi khởi tạo thông báo: $e');
    }
  }

  /// Yêu cầu cấp quyền hiển thị thông báo (Android 13+ và iOS)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[Notification] Lỗi yêu cầu cấp quyền thông báo: $e');
      return false;
    }
  }

  /// Yêu cầu cấp quyền thông báo hỗ trợ cả Mobile Native và Web/iOS Safari PWA
  Future<String> requestUniversalPermission() async {
    if (kIsWeb) {
      return await WebNotificationHelper.requestPermission();
    } else {
      final granted = await requestPermissions();
      return granted ? 'granted' : 'denied';
    }
  }

  String checkWebPermissionStatus() {
    if (kIsWeb) {
      return WebNotificationHelper.getStatus();
    }
    return 'native';
  }

  static const String defaultVapidPublicKey =
      'BLl7gtb4paS6XGzpELq49YiHVgYZiHpP7jYA0pWiJ3iTkHZeRGo-300x79e6jQ3mkxvyhbxTJZ7CB5TNOK8uaXY';

  /// Đăng ký Push Subscription với Apple / Google (WebPush VAPID)
  Future<Map<String, dynamic>?> getPushSubscription({String? vapidPublicKey}) async {
    if (!kIsWeb) return null;
    try {
      final key = vapidPublicKey ?? defaultVapidPublicKey;
      final raw = await WebNotificationHelper.subscribePush(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded.containsKey('endpoint')) {
        return decoded;
      }
    } catch (e) {
      debugPrint('[Notification] Lỗi lấy WebPush Subscription: $e');
    }
    return null;
  }

  /// Hiển thị thông báo ngay lập tức trên thanh trạng thái (hoạt động trên cả Mobile và Web/iPhone PWA)
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      WebNotificationHelper.showNotification(title, body);
      return;
    }
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'cone_channel_id',
      'Thông báo COne',
      channelDescription: 'Kênh thông báo sự kiện, điểm danh và điểm rèn luyện',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[Notification] Lỗi hiển thị thông báo: $e');
    }
  }

  /// Đặt lịch nhắc tự động trước 30 phút khi sinh viên đăng ký hoạt động
  bool scheduleActivityReminder({
    required String activityId,
    required String activityName,
    required DateTime? startTime,
    String? location,
  }) {
    cancelActivityReminder(activityId);
    if (startTime == null) return false;

    final remindAt = startTime.subtract(const Duration(minutes: 30));
    final delay = remindAt.difference(DateTime.now());
    if (delay.isNegative) return false;

    // Đặt timer nhắc khi đến giờ (tránh overflow duration quá dài > 7 ngày)
    if (delay <= const Duration(days: 7)) {
      _scheduledTimers[activityId] = Timer(delay, () {
        showNotification(
          id: activityId.hashCode,
          title: 'Sắp diễn ra hoạt động (30 phút nữa)',
          body: location != null && location.isNotEmpty
              ? '$activityName • Tại: $location'
              : activityName,
        );
        _scheduledTimers.remove(activityId);
      });
      return true;
    }
    return false;
  }

  /// Hủy nhắc lịch nếu sinh viên hủy đăng ký hoạt động
  void cancelActivityReminder(String activityId) {
    _scheduledTimers.remove(activityId)?.cancel();
  }
}
