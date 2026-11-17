import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../storage/app_storage.dart';

class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'cone_biometric_enabled';

  /// Kiểm tra thiết bị có hỗ trợ phần cứng sinh trắc học không
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('[Biometric] Lỗi kiểm tra sinh trắc học: $e');
      return false;
    }
  }

  /// Kiểm tra người dùng đã bật đăng nhập sinh trắc học chưa
  Future<bool> isBiometricEnabled() async {
    final val = await AppStorage.instance.getString(_biometricEnabledKey);
    return val == 'true';
  }

  /// Bật hoặc tắt tính năng đăng nhập sinh trắc học
  Future<void> setBiometricEnabled(bool enabled) async {
    await AppStorage.instance.setString(_biometricEnabledKey, enabled ? 'true' : 'false');
  }

  /// Mở hộp thoại quét vân tay hoặc Face ID
  Future<bool> authenticate({
    String reason = 'Xác thực vân tay hoặc Face ID để đăng nhập COne',
  }) async {
    if (kIsWeb) return false;
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint('[Biometric] Lỗi xác thực: $e');
      return false;
    }
  }
}
