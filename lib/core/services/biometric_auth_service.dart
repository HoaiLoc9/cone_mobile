import 'dart:convert';
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
  static const String _biometricUsernameKey = 'cone_bio_saved_username';
  static const String _biometricPasswordKey = 'cone_bio_saved_password';
  static const String _biometricRoleKey = 'cone_bio_saved_role';

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

  /// Lấy loại sinh trắc học khả dụng của thiết bị: 'face' (Face ID) | 'fingerprint' (Vân tay) | 'biometric' (chung)
  Future<String> getBiometricType() async {
    if (kIsWeb) {
      final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      return isApple ? 'face' : 'fingerprint';
    }
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return 'face';
      } else if (available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong)) {
        return 'fingerprint';
      }
    } catch (_) {}
    return 'biometric';
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

  /// Lưu thông tin đăng nhập phục vụ xác thực sinh trắc học Face ID / Touch ID
  Future<void> saveBiometricCredentials({
    required String username,
    required String password,
    String role = 'student',
  }) async {
    try {
      final encUser = base64Encode(utf8.encode(username.trim()));
      final encPass = base64Encode(utf8.encode(password));
      await AppStorage.instance.setString(_biometricUsernameKey, encUser);
      await AppStorage.instance.setString(_biometricPasswordKey, encPass);
      await AppStorage.instance.setString(_biometricRoleKey, role);
    } catch (e) {
      debugPrint('[Biometric] Lỗi lưu credentials: $e');
    }
  }

  /// Cập nhật mật khẩu mới khi đổi mật khẩu
  Future<void> updateSavedPassword(String newPassword) async {
    try {
      final encPass = base64Encode(utf8.encode(newPassword));
      await AppStorage.instance.setString(_biometricPasswordKey, encPass);
    } catch (_) {}
  }

  /// Lấy thông tin đăng nhập đã lưu
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final encUser = await AppStorage.instance.getString(_biometricUsernameKey);
      final encPass = await AppStorage.instance.getString(_biometricPasswordKey);
      final role = await AppStorage.instance.getString(_biometricRoleKey) ?? 'student';
      if (encUser != null && encUser.isNotEmpty && encPass != null && encPass.isNotEmpty) {
        final username = utf8.decode(base64Decode(encUser));
        final password = utf8.decode(base64Decode(encPass));
        return {
          'username': username,
          'password': password,
          'role': role,
        };
      }
    } catch (_) {}
    return null;
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
    await AppStorage.instance.remove(_biometricUsernameKey);
    await AppStorage.instance.remove(_biometricPasswordKey);
    await AppStorage.instance.remove(_biometricRoleKey);
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
