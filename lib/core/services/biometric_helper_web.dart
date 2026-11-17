import 'dart:js_interop';

@JS('isWebAuthnAvailable')
external JSPromise<JSBoolean>? _isWebAuthnAvailable();

@JS('authenticateWebBiometric')
external JSPromise<JSBoolean>? _authenticateWebBiometric(JSString reason);

Future<bool> checkWebBiometricsAvailable() async {
  try {
    final promise = _isWebAuthnAvailable();
    if (promise == null) return false;
    final res = await promise.toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> authenticateWebBiometrics(String reason) async {
  try {
    final promise = _authenticateWebBiometric(reason.toJS);
    if (promise == null) return false;
    final res = await promise.toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}
