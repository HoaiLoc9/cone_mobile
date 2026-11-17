import 'dart:js_interop';

@JS('requestWebNotificationPermission')
external JSPromise<JSString>? _requestWebNotificationPermission();

@JS('getWebNotificationStatus')
external JSString? _getWebNotificationStatus();

Future<String> requestWebPermission() async {
  try {
    final promise = _requestWebNotificationPermission();
    if (promise == null) return 'unsupported';
    final result = await promise.toDart;
    return result.toDart;
  } catch (e) {
    return 'error';
  }
}

String getWebStatus() {
  try {
    final str = _getWebNotificationStatus();
    return str?.toDart ?? 'unsupported';
  } catch (e) {
    return 'unsupported';
  }
}
