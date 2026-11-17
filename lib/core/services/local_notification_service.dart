import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'web_notification_helper.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
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

  /// Hiển thị thông báo ngay lập tức trên thanh trạng thái
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
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
}
