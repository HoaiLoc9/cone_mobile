Future<String> requestWebPermission() async => 'native';

String getWebStatus() => 'native';

void triggerWebNotification(String title, String body) {}

Future<String?> subscribePushWeb(String vapidPublicKey) async => null;
