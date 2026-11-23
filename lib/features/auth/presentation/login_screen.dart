import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../features/admin/data/admin_models.dart';
import '../../../features/admin/data/admin_service.dart';
import '../../../features/admin/presentation/admin_forgot_password_screen.dart';
import '../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.adminService,
    required this.onLoggedIn,
    required this.onAdminLoggedIn,
  });

  final AuthService authService;
  final AdminService adminService;
  final ValueChanged<AuthSession> onLoggedIn;
  final ValueChanged<AdminSession> onAdminLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;
  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;
  String _biometricType = 'biometric';

  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectBiometric();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    try {
      final savedUser = await AppStorage.instance.getString('cone_remembered_username');
      if (savedUser != null && savedUser.trim().isNotEmpty && mounted) {
        setState(() {
          identifierController.text = savedUser.trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _detectBiometric() async {
    final type = await BiometricAuthService.instance.getBiometricType();
    if (mounted) {
      setState(() => _biometricType = type);
    }
  }

  Future<void> _showServerConfigDialog() async {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? testResult;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.dns_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Cấu hình máy chủ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Địa chỉ API máy chủ:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'https://cofer.io.vn/api/mobile',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    testResult!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: testResult!.contains('thành công')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ApiConfig.resetToDefault();
                  controller.text = ApiConfig.baseUrl;
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Mặc định'),
              ),
              OutlinedButton(
                onPressed: testing
                    ? null
                    : () async {
                        setDialogState(() => testing = true);
                        try {
                          ApiConfig.setBaseUrl(controller.text);
                          final client = ApiClient();
                          await client.get('/mobile/login');
                          setDialogState(() => testResult = 'Kết nối máy chủ thành công!');
                        } on ApiException catch (e) {
                          if ((e.statusCode ?? 0) > 0) {
                            setDialogState(() => testResult = 'Kết nối máy chủ thành công (HTTP ${e.statusCode})!');
                          } else {
                            setDialogState(() => testResult = 'Lỗi kết nối: ${e.message}');
                          }
                        } catch (e) {
                          setDialogState(() => testResult = 'Lỗi: $e');
                        } finally {
                          setDialogState(() => testing = false);
                        }
                      },
                child: testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kiểm tra'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  await ApiConfig.saveConfig(controller.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập tài khoản/MSSV và mật khẩu.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final isLikelyAdmin = identifier.toLowerCase().contains('admin') ||
          identifier.toLowerCase().startsWith('gv') ||
          identifier.toLowerCase().startsWith('cb');

      if (isLikelyAdmin) {
        // Thử đăng nhập Quản trị / Giảng viên trước
        try {
          final adminSession = await widget.adminService.login(
            email: identifier,
            password: password,
          );
          await BiometricAuthService.instance.saveBiometricCredentials(
            username: identifier,
            password: password,
            role: 'admin',
          );
          await AppStorage.instance.setString('cone_remembered_username', identifier.trim());
          widget.onAdminLoggedIn(adminSession);
          return;
        } on ApiException catch (adminErr) {
          final code = adminErr.statusCode ?? 0;
          if (code != 401 && code != 404 && code != 422 && code != 400) {
            rethrow;
          }
          // Thử tiếp tài khoản Sinh viên nếu Quản trị không khớp
          try {
            final studentSession = await widget.authService.login(
              identifier: identifier,
              password: password,
            );
            await widget.authService.saveSession(studentSession);
            await BiometricAuthService.instance.saveBiometricCredentials(
              username: identifier,
              password: password,
              role: 'student',
            );
            await BiometricAuthService.instance.saveBiometricSession(
              studentSession.token,
              jsonEncode(studentSession.user.toJson()),
            );
            await AppStorage.instance.setString('cone_remembered_username', identifier.trim());
            widget.onLoggedIn(studentSession);
            return;
          } on ApiException {
            setState(() {
              errorMessage = adminErr.message.isNotEmpty
                  ? adminErr.message
                  : 'Tài khoản hoặc mật khẩu không chính xác.';
            });
          }
        }
      } else {
        // Mặc định thử đăng nhập Sinh viên trước
        try {
          final studentSession = await widget.authService.login(
            identifier: identifier,
            password: password,
          );
          await widget.authService.saveSession(studentSession);
          await BiometricAuthService.instance.saveBiometricCredentials(
            username: identifier,
            password: password,
            role: 'student',
          );
          await BiometricAuthService.instance.saveBiometricSession(
            studentSession.token,
            jsonEncode(studentSession.user.toJson()),
          );
          await AppStorage.instance.setString('cone_remembered_username', identifier.trim());
          widget.onLoggedIn(studentSession);
          return;
        } on ApiException catch (studentErr) {
          final code = studentErr.statusCode ?? 0;
          if (code != 401 && code != 404 && code != 422 && code != 400) {
            rethrow;
          }
          // Thử tiếp tài khoản Quản trị / Cán bộ nếu Sinh viên không khớp
          try {
            final adminSession = await widget.adminService.login(
              email: identifier,
              password: password,
            );
            await BiometricAuthService.instance.saveBiometricCredentials(
              username: identifier,
              password: password,
              role: 'admin',
            );
            await AppStorage.instance.setString('cone_remembered_username', identifier.trim());
            widget.onAdminLoggedIn(adminSession);
            return;
          } on ApiException {
            setState(() {
              errorMessage = studentErr.message.isNotEmpty
                  ? studentErr.message
                  : 'Tài khoản hoặc mật khẩu không chính xác.';
            });
          }
        }
      }
    } on ApiException catch (error) {
      setState(() => errorMessage = error.message);
    } catch (error) {
      setState(() {
        errorMessage = 'Không thể kết nối máy chủ: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final available = await BiometricAuthService.instance.isBiometricsAvailable();
    final bioName = _biometricType == 'face'
        ? 'Face ID'
        : (_biometricType == 'fingerprint' ? 'Vân tay' : 'Sinh trắc học');

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thiết bị chưa cài đặt $bioName hoặc trình duyệt chưa cấp quyền.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
      return;
    }

    final creds = await BiometricAuthService.instance.getSavedCredentials();

    if (creds == null) {
      final idText = identifierController.text.trim();
      final passText = passwordController.text;

      if (idText.isNotEmpty && passText.isNotEmpty) {
        final authenticated = await BiometricAuthService.instance.authenticate(
          reason: 'Xác thực $bioName để kích hoạt đăng nhập nhanh',
        );
        if (authenticated && mounted) {
          _submit();
        }
        return;
      }

      if (mounted) {
        _showBiometricSetupSheet(bioName);
      }
      return;
    }

    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'Xác thực $bioName để đăng nhập vào COne',
    );

    if (authenticated && mounted) {
      setState(() => isLoading = true);
      try {
        final username = creds['username']!;
        final pass = creds['password']!;
        final role = creds['role'] ?? 'student';

        if (role == 'admin') {
          try {
            final adminSession = await widget.adminService.login(
              email: username,
              password: pass,
            );
            await AppStorage.instance.setString('cone_remembered_username', username.trim());
            widget.onAdminLoggedIn(adminSession);
            return;
          } catch (_) {}
        }

        // Đăng nhập lấy phiên mới 100% từ server
        final studentSession = await widget.authService.login(
          identifier: username,
          password: pass,
        );
        await widget.authService.saveSession(studentSession);
        await BiometricAuthService.instance.saveBiometricSession(
          studentSession.token,
          jsonEncode(studentSession.user.toJson()),
        );
        widget.onLoggedIn(studentSession);
        return;
      } catch (e) {
        if (mounted) {
          // Nếu mật khẩu cũ không còn hợp lệ, mở sheet để cập nhật mật khẩu mới
          if (e is ApiException && e.statusCode == 401) {
            _showBiometricSetupSheet(bioName, prefilledUser: creds['username']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng nhập $bioName không thành công: ${e is ApiException ? e.message : "Vui lòng kiểm tra mật khẩu."}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _showBiometricSetupSheet(String bioName, {String? prefilledUser}) {
    final setupIdCtrl = TextEditingController(
      text: (prefilledUser != null && prefilledUser.isNotEmpty)
          ? prefilledUser
          : identifierController.text.trim(),
    );
    final setupPassCtrl = TextEditingController();
    bool setupLoading = false;
    String? setupError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _biometricType == 'face'
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kích hoạt $bioName',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xác thực 1 lần để lưu vào máy an toàn',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.adaptiveTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (setupError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      setupError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: setupIdCtrl,
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'MSSV / Tài khoản',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: setupPassCtrl,
                  obscureText: true,
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Xác thực & Kích hoạt $bioName',
                  isLoading: setupLoading,
                  onPressed: () async {
                    final id = setupIdCtrl.text.trim();
                    final pwd = setupPassCtrl.text;
                    if (id.isEmpty || pwd.isEmpty) {
                      setSheetState(() => setupError = 'Vui lòng nhập đầy đủ tài khoản và mật khẩu.');
                      return;
                    }
                    setSheetState(() {
                      setupLoading = true;
                      setupError = null;
                    });
                    try {
                      final authenticated = await BiometricAuthService.instance.authenticate(
                        reason: 'Xác thực $bioName để liên kết tài khoản COne',
                      );
                      if (!authenticated) {
                        setSheetState(() {
                          setupLoading = false;
                          setupError = 'Xác thực $bioName không thành công.';
                        });
                        return;
                      }

                      // Đăng nhập thử để đảm bảo tài khoản & mật khẩu chuẩn xác
                      final studentSession = await widget.authService.login(
                        identifier: id,
                        password: pwd,
                      );
                      await widget.authService.saveSession(studentSession);
                      await BiometricAuthService.instance.saveBiometricCredentials(
                        username: id,
                        password: pwd,
                        role: 'student',
                      );
                      await BiometricAuthService.instance.saveBiometricSession(
                        studentSession.token,
                        jsonEncode(studentSession.user.toJson()),
                      );
                      await AppStorage.instance.setString('cone_remembered_username', id);

                      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                      if (mounted) widget.onLoggedIn(studentSession);
                    } catch (err) {
                      setSheetState(() {
                        setupLoading = false;
                        setupError = err is ApiException ? err.message : err.toString();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAdminForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminForgotPasswordScreen(service: widget.adminService),
      ),
    );
  }

  void _showForgotPasswordHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hướng dẫn khôi phục tài khoản COne',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Khối Dành cho Sinh viên
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SINH VIÊN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hướng dẫn cho sinh viên',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.key_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mật khẩu mặc định: Trường khởi tạo mật khẩu là Ngày sinh (định dạng ddmmyyyy, ví dụ: sinh 15/08/2004 nhập là 15082004) hoặc số CCCD.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nếu đã đổi mật khẩu và quên: Vui lòng liên hệ Cố vấn học tập (GVCN) hoặc Văn phòng Công tác Sinh viên (CTSV) kèm Họ tên & MSSV để được hỗ trợ đặt lại mật khẩu nhanh nhất.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Khối Dành cho Cán bộ / Giảng viên
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CÁN BỘ / GIẢNG VIÊN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cán bộ có thể tự đặt lại mật khẩu bằng mã OTP bảo mật gửi đến Email trường cấp (@cofer.edu.vn).',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openAdminForgotPassword();
                      },
                      icon: const Icon(Icons.mail_lock_rounded, size: 18),
                      label: const Text(
                        'Đặt lại mật khẩu Cán bộ qua OTP Email',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu & Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroBgHeight = (screenHeight * 0.42).clamp(260.0, 390.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: Stack(
        children: [
          // 1. Nền xanh nhạt mềm mại chuyển sắc toàn màn hình
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2FE),
                    Color(0xFFEAF4FF),
                    Color(0xFFF4F9FF),
                    Color(0xFFE5F0FF),
                  ],
                ),
              ),
            ),
          ),

          // 2. Ảnh nền khuôn viên trường đại học nắng sáng ở phần đầu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroBgHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/login_campus_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/campus_real.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                // Lớp sương sáng dịu ở giữa giúp logo & chữ COne luôn nổi bật sắc nét
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.72,
                      colors: [
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Chuyển tiếp mờ êm ở mép dưới vào sóng xanh nhạt
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 95,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEAF4FF).withValues(alpha: 0.0),
                          const Color(0xFFEAF4FF).withValues(alpha: 0.85),
                          const Color(0xFFEAF4FF),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Dải sóng mềm mại phía sau khung đăng nhập
          Positioned(
            top: heroBgHeight - 68,
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: _LoginWaveBackdropPainter(),
            ),
          ),

          // Nút chuyển nhanh ngôn ngữ VI / EN ở góc trên phải
          Positioned(
            top: 10,
            right: 16,
            child: SafeArea(
              child: LanguageToggleChip(lightOnDark: false),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                if (isWide) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildBrandingHero(isWide: true)),
                            const SizedBox(width: 48),
                            Expanded(child: _buildFormCard3D(isWide: true)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildBrandingHero(isWide: false),
                          const SizedBox(height: 24),
                          _buildFormCard3D(isWide: false),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingHero({required bool isWide}) {
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // 3D Glass Box Logo with Glow & Active Badge
        GestureDetector(
          onLongPress: _showServerConfigDialog,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isWide ? 88 : 82,
                height: isWide ? 88 : 82,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/cofer_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
              ),
              // Online status indicator dot on logo
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              // 3 tia trang trí nhỏ phía trên góc phải logo
              Positioned(
                top: -12,
                right: -18,
                child: CustomPaint(
                  size: const Size(22, 22),
                  painter: _LogoSparklePainter(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Tiêu đề thương hiệu 2 tông màu: C (navy) + One (blue)
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.05,
            ),
            children: [
              TextSpan(
                text: 'C',
                style: TextStyle(color: Color(0xFF0F172A)),
              ),
              TextSpan(
                text: 'One',
                style: TextStyle(color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          tr(
            'Hệ thống Điểm rèn luyện sinh viên',
            'Student Conduct & Activity Portal',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        // University badge pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tr(
                    'Trường Cao đẳng Kinh tế Đối ngoại',
                    'College of Foreign Economic Relations',
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard3D({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Đăng nhập', 'Sign In'),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr('Chào mừng bạn quay trở lại! 👋', 'Welcome back! 👋'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildInputField3D(
            label: tr('MÃ SINH VIÊN / EMAIL', 'STUDENT ID / EMAIL'),
            hint: tr('VD: 22714652 hoặc admin@cofer.edu.vn', 'e.g. 22714652 or admin@cofer.edu.vn'),
            icon: Icons.person_outline_rounded,
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildInputField3D(
            label: tr('MẬT KHẨU', 'PASSWORD'),
            hint: tr('Nhập mật khẩu của bạn', 'Enter your password'),
            icon: Icons.lock_outline_rounded,
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: isLoading
                  ? null
                  : () => setState(() => obscurePassword = !obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: rememberMe,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: isLoading
                      ? null
                      : (val) => setState(() => rememberMe = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Ghi nhớ đăng nhập', 'Remember me'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isLoading ? null : _showForgotPasswordHelp,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  tr('Quên mật khẩu?', 'Forgot password?'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          // Nút Đăng nhập Gradient dạng viên thuốc nổi bật
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _submit,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr('ĐĂNG NHẬP NGAY', 'SIGN IN NOW'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 19),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Divider "HOẶC TIẾP TỤC VỚI"
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr('HOẶC TIẾP TỤC VỚI', 'OR CONTINUE WITH'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 18),
          // Nút Đăng nhập bằng Sinh trắc học (Tự động nhận diện Face ID / Vân tay theo phần cứng thiết bị)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _handleBiometricLogin,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _biometricType == 'face'
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _biometricType == 'face'
                                ? tr('Đăng nhập bằng Face ID', 'Sign in with Face ID')
                                : (_biometricType == 'fingerprint'
                                    ? tr('Đăng nhập bằng Vân tay', 'Sign in with Fingerprint')
                                    : tr('Đăng nhập sinh trắc học', 'Biometric Sign In')),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _biometricType == 'face'
                                ? tr('Nhận diện khuôn mặt Face ID an toàn', 'Secure Face ID authentication')
                                : (_biometricType == 'fingerprint'
                                    ? tr('Chạm vân tay để xác thực nhanh', 'Touch sensor for quick sign in')
                                    : tr('Xác thực sinh trắc học không cần mật khẩu', 'Passwordless biometric authentication')),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField3D({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: !isLoading,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginWaveBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backWave = Paint()
      ..color = const Color(0xFFD6E9FF).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, 32)
      ..quadraticBezierTo(size.width * 0.28, -8, size.width * 0.56, 26)
      ..quadraticBezierTo(size.width * 0.82, 56, size.width, 18)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, backWave);

    final frontWave = Paint()
      ..color = const Color(0xFFF3F8FF)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, 50)
      ..quadraticBezierTo(size.width * 0.34, 8, size.width * 0.68, 42)
      ..quadraticBezierTo(size.width * 0.88, 60, size.width, 36)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontPath, frontWave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3 nét tia trang trí tinh tế giống bản thiết kế
    canvas.drawLine(const Offset(4, 10), const Offset(6, 2), paint);
    canvas.drawLine(const Offset(9, 13), const Offset(17, 6), paint);
    canvas.drawLine(const Offset(11, 18), const Offset(20, 17), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
