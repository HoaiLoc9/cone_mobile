import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/admin_service.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminForgotPasswordScreen> createState() =>
      _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 0;
  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email quản trị.');
      return Future.value();
    }
    return _run(() async {
      await widget.service.requestPasswordOtp(email);
      setState(() {
        _step = 1;
        _message =
            'Mã OTP đã được gửi. Vui lòng kiểm tra email của bạn.';
      });
    });
  }

  Future<void> _verifyOtp() {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'OTP phải gồm 6 số.');
      return Future.value();
    }
    return _run(() async {
      await widget.service.verifyPasswordOtp(email: email, otp: otp);
      setState(() {
        _step = 2;
        _message = 'OTP hợp lệ. Bạn có thể đặt mật khẩu mới.';
      });
    });
  }

  Future<void> _resetPassword() {
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Mật khẩu mới tối thiểu 6 ký tự.');
      return Future.value();
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp.');
      return Future.value();
    }
    return _run(() async {
      await widget.service.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lại mật khẩu thành công.')),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quên mật khẩu admin',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBlue.withValues(alpha: .08),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Email → OTP → đặt lại mật khẩu cho tài khoản quản trị level 0/1/2.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email quản trị',
                      hint: 'admin@email.com',
                      icon: Icons.mail_outline_rounded,
                      enabled: !_isLoading && _step == 0,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (_step >= 1) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _otpController,
                        label: 'OTP',
                        hint: '6 số',
                        icon: Icons.password_rounded,
                        enabled: !_isLoading && _step <= 1,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (_step >= 2) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu mới',
                        hint: 'Tối thiểu 6 ký tự',
                        icon: Icons.lock_reset_rounded,
                        enabled: !_isLoading,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmController,
                        label: 'Xác nhận mật khẩu',
                        hint: 'Nhập lại mật khẩu mới',
                        icon: Icons.lock_outline_rounded,
                        enabled: !_isLoading,
                        obscureText: true,
                      ),
                    ],
                    if (_message != null || _error != null) ...[
                      const SizedBox(height: 16),
                      _Notice(
                        message: _message ?? _error!,
                        isError: _error != null,
                      ),
                    ],
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: _buttonLabel,
                      isLoading: _isLoading,
                      onPressed: _step == 0
                          ? _requestOtp
                          : _step == 1
                          ? _verifyOtp
                          : _resetPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title => switch (_step) {
    0 => 'Nhập email',
    1 => 'Xác minh OTP',
    _ => 'Đặt mật khẩu mới',
  };

  String get _buttonLabel => switch (_step) {
    0 => 'Gửi OTP',
    1 => 'Xác minh OTP',
    _ => 'Đặt lại mật khẩu',
  };
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : const Color(0xFF059669);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
