import 'web_notification_helper_io.dart'
    if (dart.library.js_interop) 'web_notification_helper_web.dart';

abstract class WebNotificationHelper {
  static Future<String> requestPermission() => requestWebPermission();
  static String getStatus() => getWebStatus();
  static void showNotification(String title, String body) =>
      triggerWebNotification(title, body);
}
