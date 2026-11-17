import 'biometric_helper_io.dart'
    if (dart.library.js_interop) 'biometric_helper_web.dart';

abstract class BiometricHelper {
  static Future<bool> isAvailable() => checkWebBiometricsAvailable();
  static Future<bool> authenticate(String reason) => authenticateWebBiometrics(reason);
}
