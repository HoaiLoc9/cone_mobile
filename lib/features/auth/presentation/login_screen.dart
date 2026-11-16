import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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
  bool isStudent = true;
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

  void _switchRole(bool student) {
    if (isLoading || isStudent == student) return;

    setState(() {
      isStudent = student;
      errorMessage = null;
      identifierController.clear();
      passwordController.clear();
    });
  }

  Future<void> _submit() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = isStudent
            ? 'Vui lòng nhập mã sinh viên/email và mật khẩu.'
            : 'Vui lòng nhập email quản trị và mật khẩu.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isStudent) {
        final session = await widget.authService.login(
          identifier: identifier,
          password: password,
        );
        widget.onLoggedIn(session);
      } else {
        final session = await widget.adminService.login(
          email: identifier,
          password: password,
        );
        widget.onAdminLoggedIn(session);
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
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 3D Ambient Glowing Spheres (Không gian chiều sâu phía sau)
          Positioned(
            top: -60,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.18),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          _buildBrandingHero(isWide: false),
                          const SizedBox(height: 20),
                          _buildFormCard3D(isWide: false),
                          const SizedBox(height: 20),
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
        // 3D Glass Box Logo
        Container(
          width: isWide ? 88 : 80,
          height: isWide ? 88 : 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              const BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/cofer_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Text(
              'COne',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                '3D PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Hệ thống Điểm rèn luyện sinh viên',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isStudent
              ? 'Đồng hành rèn luyện & phát triển toàn diện'
              : 'Cổng thông tin quản trị viên & giảng viên',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard3D({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoleSegment3D(),
          const SizedBox(height: 24),
          Text(
            isStudent ? 'Đăng nhập Sinh viên' : 'Đăng nhập Quản trị',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isStudent
                ? 'Nhập MSSV hoặc email để vào hệ thống'
                : 'Dành cho GVCN và ban cán sự',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          _buildInputField3D(
            label: isStudent ? 'MÃ SINH VIÊN / EMAIL' : 'EMAIL QUẢN TRỊ',
            hint: isStudent ? 'VD: SV001' : 'admin@domain.com',
            icon: isStudent ? Icons.badge_rounded : Icons.admin_panel_settings_rounded,
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildInputField3D(
            label: 'MẬT KHẨU',
            hint: '••••••••',
            icon: Icons.lock_rounded,
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
                width: 24,
                height: 24,
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
                'Ghi nhớ tài khoản',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (!isStudent)
                TextButton(
                  onPressed: isLoading ? null : _openAdminForgotPassword,
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
                borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 24),
          // Nút Đăng nhập 3D Tactile Neon Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _submit,
              borderRadius: BorderRadius.circular(18),
              child: Container(
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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.45),
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
                            const Icon(Icons.login_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isStudent ? 'ĐĂNG NHẬP NGAY' : 'ĐĂNG NHẬP QUẢN TRỊ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSegment3D() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleButton3D(
              title: 'Sinh viên',
              icon: Icons.school_rounded,
              isActive: isStudent,
              onTap: () => _switchRole(true),
            ),
          ),
          Expanded(
            child: _buildRoleButton3D(
              title: 'Cán bộ / GVCN',
              icon: Icons.admin_panel_settings_rounded,
              isActive: !isStudent,
              onTap: () => _switchRole(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton3D({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
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
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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
                  color: Colors.black.withValues(alpha: 0.04),
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
                      ? 'Máy chủ: $hostDisplay (Sẵn sàng)'
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
                const Icon(Icons.settings_outlined, size: 14, color: Color(0xFF94A3B8)),
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
