import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../storage/app_storage.dart';
import 'biometric_helper.dart';

class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'cone_biometric_enabled';
  static const String _biometricTokenKey = 'cone_bio_saved_token';
  static const String _biometricUserKey = 'cone_bio_saved_user';

  /// Kiểm tra thiết bị có hỗ trợ phần cứng sinh trắc học không (Android, iOS Native & iOS Safari PWA/Web)
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) {
      return await BiometricHelper.isAvailable();
    }
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
    if (!enabled) {
      await clearBiometricSession();
    }
  }

  /// Lưu trữ phiên đăng nhập dành riêng cho Sinh trắc học (vân tay / Face ID)
  Future<void> saveBiometricSession(String token, String userJsonStr) async {
    await AppStorage.instance.setString(_biometricTokenKey, token);
    await AppStorage.instance.setString(_biometricUserKey, userJsonStr);
  }

  /// Lấy phiên đăng nhập sinh trắc học đã lưu
  Future<Map<String, String>?> getBiometricSession() async {
    final token = await AppStorage.instance.getString(_biometricTokenKey);
    final userStr = await AppStorage.instance.getString(_biometricUserKey);
    if (token != null && token.isNotEmpty && userStr != null && userStr.isNotEmpty) {
      return {'token': token, 'user': userStr};
    }
    return null;
  }

  /// Xóa phiên sinh trắc học
  Future<void> clearBiometricSession() async {
    await AppStorage.instance.remove(_biometricTokenKey);
    await AppStorage.instance.remove(_biometricUserKey);
  }

  /// Mở hộp thoại quét vân tay hoặc Face ID
  Future<bool> authenticate({
    String reason = 'Xác thực vân tay hoặc Face ID để tiếp tục',
  }) async {
    if (kIsWeb) {
      return await BiometricHelper.authenticate(reason);
    }
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
