import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/biometric_auth_service.dart';
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

  bool? _isServerConnected;
  bool _isCheckingServer = false;

  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    if (!mounted) return;
    setState(() => _isCheckingServer = true);
    try {
      final client = ApiClient();
      await client.get('/mobile/login');
      if (mounted) setState(() => _isServerConnected = true);
    } on ApiException catch (e) {
      // 401, 404, 405, 422 indicate the server is online and responding!
      final status = e.statusCode;
      if (status != null && status > 0) {
        if (mounted) setState(() => _isServerConnected = true);
      } else {
        if (mounted) setState(() => _isServerConnected = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isServerConnected = false);
    } finally {
      if (mounted) setState(() => _isCheckingServer = false);
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
                  _checkServerConnection();
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
                  _checkServerConnection();
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
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị chưa cài đặt Face ID/Vân tay hoặc trình duyệt chưa cấp quyền.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
      return;
    }

    final creds = await BiometricAuthService.instance.getSavedCredentials();

    if (creds == null) {
      // Nếu chưa lưu thông tin Face ID:
      // Kiểm tra xem người dùng có đang điền sẵn tài khoản & mật khẩu trong ô không
      final idText = identifierController.text.trim();
      final passText = passwordController.text;

      if (idText.isNotEmpty && passText.isNotEmpty) {
        final authenticated = await BiometricAuthService.instance.authenticate(
          reason: 'Xác thực vân tay hoặc Face ID để kích hoạt đăng nhập nhanh',
        );
        if (authenticated && mounted) {
          _submit();
        }
        return;
      }

      // Xóa phiên sinh trắc học cũ đã hết hạn để tránh bị loop lỗi 401
      await BiometricAuthService.instance.clearBiometricSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập MSSV & Mật khẩu đăng nhập 1 lần để kích hoạt Face ID cho máy này.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'Xác thực vân tay hoặc Face ID để đăng nhập vào COne',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập Face ID không thành công: ${e is ApiException ? e.message : "Vui lòng nhập mật khẩu."}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _openAdminForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminForgotPasswordScreen(service: widget.adminService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Glowing Spheres (Không gian chiều sâu tinh tế)
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
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
                          const SizedBox(height: 24),
                          _buildFooter(),
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
        Stack(
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
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // App title with stylized gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'COne',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hệ thống Điểm rèn luyện sinh viên',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        // University badge pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Trường Cao đẳng Kinh tế Đối ngoại',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chào mừng bạn quay trở lại! 👋',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
            label: 'MÃ SINH VIÊN / EMAIL',
            hint: 'VD: 22714652 hoặc admin@cofer.edu.vn',
            icon: Icons.person_outline_rounded,
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildInputField3D(
            label: 'MẬT KHẨU',
            hint: 'Nhập mật khẩu của bạn',
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
              const Text(
                'Ghi nhớ đăng nhập',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: isLoading ? null : _openAdminForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
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
          // Nút Đăng nhập Gradient nổi bật
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _submit,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.38),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ĐĂNG NHẬP NGAY',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 19),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Divider "HOẶC TIẾP TỤC VỚI"
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'HOẶC TIẾP TỤC VỚI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 18),
          // Nút Đăng nhập bằng Sinh trắc học (Face ID / Vân tay) thiết kế Capsule Card cao cấp
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
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đăng nhập bằng Face ID / Vân tay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Xác thực tức thì không cần nhập mật khẩu',
                            style: TextStyle(
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

  Widget _buildFooter() {
    final hostDisplay = Uri.tryParse(ApiConfig.webUrl)?.host ?? ApiConfig.webUrl;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showServerConfigDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isCheckingServer
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isServerConnected == true
                              ? const Color(0xFF10B981)
                              : _isServerConnected == false
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                        ),
                      ),
                const SizedBox(width: 8),
                Text(
                  _isServerConnected == true
                      ? 'Máy chủ: $hostDisplay (Trực tuyến)'
                      : _isServerConnected == false
                          ? 'Máy chủ: $hostDisplay (Chưa kết nối)'
                          : 'Đang kiểm tra kết nối...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isServerConnected == false
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'COne Mobile • Điểm rèn luyện trực tuyến',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
