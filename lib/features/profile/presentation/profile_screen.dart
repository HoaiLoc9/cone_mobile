import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/auth_service.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';
import 'digital_student_id_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.service,
    required this.session,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  final ProfileService service;
  final AuthSession session;
  final ValueChanged<ProfileUser> onProfileUpdated;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _otpController = TextEditingController();

  ProfileUser? _user;
  ProfileUpload? _avatarUpload;
  bool _isLoading = true;
  bool _isSubmittingRequest = false;
  bool _isSendingOtp = false;
  bool _isSavingPassword = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isEditingContact = false;
  bool _isPasswordSectionExpanded = false;

  int _otpCountdown = 0;
  Timer? _countdownTimer;

  Map<String, dynamic>? _pendingRequest;

  String? _errorMessage;
  String? _successMessage;

  bool _biometricEnabled = false;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _requestKey(String userId) => 'cone_pending_profile_req_$userId';

  Future<void> _loadPendingRequest(String userId) async {
    try {
      final raw = await AppStorage.instance.getString(_requestKey(userId));
      if (raw != null && raw.isNotEmpty) {
        setState(() {
          _pendingRequest = jsonDecode(raw) as Map<String, dynamic>;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePendingRequest(
    String userId,
    Map<String, dynamic>? data,
  ) async {
    try {
      if (data == null) {
        await AppStorage.instance.remove(_requestKey(userId));
      } else {
        await AppStorage.instance.setString(_requestKey(userId), jsonEncode(data));
      }
    } catch (_) {}
    setState(() {
      _pendingRequest = data;
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.fetchProfile();
      _applyUser(data.user);

      // Đồng bộ yêu cầu thay đổi thông tin từ server
      final pendingApi = await widget.service.fetchPendingRequest();
      if (pendingApi != null && pendingApi['status'] == 'pending') {
        final reqData = (pendingApi['requested_data'] as Map<String, dynamic>?) ?? {};
        final mapped = {
          'requested_at': pendingApi['submitted_at'] ?? 'Vừa xong',
          'status': pendingApi['status_label'] ?? 'Chờ phê duyệt',
          'email': reqData['email'] ?? '',
          'phone': reqData['phone'] ?? '',
          'address': reqData['address'] ?? '',
        };
        await _savePendingRequest(data.user.id, mapped);
      } else if (pendingApi != null && pendingApi['status'] != 'pending') {
        await _savePendingRequest(data.user.id, null);
      } else {
        await _loadPendingRequest(data.user.id);
      }

      final bioEnabled = await BiometricAuthService.instance.isBiometricEnabled();
      final appLock = await BiometricAuthService.instance.isAppLockEnabled();
      if (mounted) {
        setState(() {
          _biometricEnabled = bioEnabled;
          _appLockEnabled = appLock;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Không thể tải thông tin hồ sơ.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyUser(ProfileUser user) {
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _addressController.text = user.address;
    setState(() {
      _user = user;
      _avatarUpload = null;
    });
    widget.onProfileUpdated(user);
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) {
      return;
    }
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
      maxDimension: 800,
      quality: 85,
    );
    setState(
      () => _avatarUpload = ProfileUpload(name: compressed.name, bytes: compressed.bytes),
    );
  }

  Future<void> _submitProfileChangeRequest() async {
    final user = _user;
    if (user == null) return;

    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newAddress = _addressController.text.trim();

    if (newEmail.isEmpty || newPhone.isEmpty) {
      setState(
        () => _errorMessage = 'Vui lòng điền đầy đủ email và số điện thoại.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10),
                Text(
                  'Gửi yêu cầu xét duyệt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              'Thông tin cá nhân của sinh viên cần được GVCN hoặc Ban cán sự kiểm tra và phê duyệt trước khi cập nhật chính thức.\n\nBạn có muốn gửi yêu cầu thay đổi thông tin này không?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.adaptiveTextSecondary,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmittingRequest = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.service.submitProfileChangeRequest(
        email: newEmail,
        phone: newPhone,
        address: newAddress,
        avatar: _avatarUpload,
      );

      final now = DateTime.now();
      final dateStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ngày ${now.day}/${now.month}/${now.year}';

      final requestData = {
        'email': newEmail,
        'phone': newPhone,
        'address': newAddress,
        'avatar_name': _avatarUpload?.name,
        'requested_at': dateStr,
        'status': 'Chờ phê duyệt',
      };

      await _savePendingRequest(user.id, requestData);

      setState(() {
        _isEditingContact = false;
        _successMessage =
            'Đã gửi yêu cầu thay đổi thông tin thành công! Vui lòng chờ GVCN xét duyệt.';
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể gửi yêu cầu thay đổi thông tin.');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRequest = false);
      }
    }
  }

  Future<void> _cancelProfileRequest() async {
    final user = _user;
    if (user == null) return;
    try {
      await widget.service.cancelProfileRequest();
    } catch (_) {}
    await _savePendingRequest(user.id, null);
    setState(() {
      _successMessage = 'Đã hủy yêu cầu thay đổi thông tin.';
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _otpCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _otpCountdown = 0);
        }
      } else {
        if (mounted) {
          setState(() => _otpCountdown--);
        }
      }
    });
  }

  Future<void> _sendPasswordOtp() async {
    final user = _user;
    if (user == null) return;

    final targetEmail = user.email.isNotEmpty ? user.email : _emailController.text.trim();
    if (targetEmail.isEmpty) {
      setState(() => _errorMessage = 'Không tìm thấy địa chỉ email của bạn để nhận mã OTP.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.service.sendPasswordOtp(targetEmail);
      setState(() {
        _otpSent = true;
        _successMessage = 'Mã xác thực OTP đã được gửi đến email $targetEmail. Vui lòng kiểm tra hộp thư.';
      });
      _startCountdown();
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể gửi mã OTP. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _passwordConfirmController.text.trim();
    final otp = _otpController.text.trim();

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu mới phải có tối thiểu 6 ký tự.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }

    if (!_otpSent) {
      setState(() => _errorMessage = 'Vui lòng bấm "Gửi mã OTP qua email" trước khi đổi mật khẩu.');
      return;
    }

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Vui lòng nhập đúng mã xác thực OTP từ email.');
      return;
    }

    setState(() {
      _isSavingPassword = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.service.changePassword(
        password: newPassword,
        passwordConfirmation: confirmPassword,
        otp: otp,
      );
      await BiometricAuthService.instance.updateSavedPassword(newPassword);
      _passwordController.clear();
      _passwordConfirmController.clear();
      _otpController.clear();
      _countdownTimer?.cancel();
      setState(() {
        _otpSent = false;
        _otpCountdown = 0;
        _isPasswordSectionExpanded = false;
        _successMessage = 'Đổi mật khẩu thành công bằng mã OTP email!';
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể đổi mật khẩu. Vui lòng kiểm tra lại mã OTP.');
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  Future<String?> _promptPasswordForBiometrics() async {
    final pwdCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Lưu mật khẩu sinh trắc học', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vui lòng nhập mật khẩu đăng nhập để hoàn tất liên kết Face ID / Vân tay cho các lần đăng nhập tiếp theo:',
              style: TextStyle(fontSize: 13, color: AppColors.adaptiveTextSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(pwdCtrl.text),
            child: const Text('Xác nhận & Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool val) async {
    if (val) {
      final authenticated = await BiometricAuthService.instance.authenticate(
        reason: 'Xác thực vân tay hoặc Face ID để kích hoạt tính năng này',
      );
      if (authenticated) {
        final existingCreds = await BiometricAuthService.instance.getSavedCredentials();
        if (existingCreds == null && mounted) {
          final pwd = await _promptPasswordForBiometrics();
          if (pwd != null && pwd.isNotEmpty) {
            await BiometricAuthService.instance.saveBiometricCredentials(
              username: widget.session.user.code.isNotEmpty ? widget.session.user.code : widget.session.user.email,
              password: pwd,
              role: 'student',
            );
          }
        }
        await BiometricAuthService.instance.setBiometricEnabled(true);
        await BiometricAuthService.instance.saveBiometricSession(
          widget.session.token,
          jsonEncode(widget.session.user.toJson()),
        );
        if (mounted) {
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã bật đăng nhập bằng vân tay/Face ID thành công! 🎉'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _biometricEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực Face ID/Vân tay không thành công hoặc thiết bị chưa hỗ trợ.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } else {
      await BiometricAuthService.instance.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tắt đăng nhập bằng vân tay/Face ID.'),
            backgroundColor: Color(0xFF475569),
          ),
        );
      }
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      final success = await BiometricAuthService.instance.authenticate(
        reason: 'Xác thực để kích hoạt tính năng Khóa ứng dụng bảo mật',
      );
      if (!success) return;
    }
    await BiometricAuthService.instance.setAppLockEnabled(value);
    if (mounted) {
      setState(() => _appLockEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Đã bật Khóa ứng dụng bảo vệ bằng sinh trắc học.'
              : 'Đã tắt Khóa ứng dụng.'),
          backgroundColor: value ? const Color(0xFF10B981) : const Color(0xFF475569),
        ),
      );
    }
  }

  void _checkUpdate() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COne Mobile',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.adaptiveTextPrimary,
                          ),
                        ),
                        const Text(
                          'Phiên bản mới nhất: v1.0.4',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Nhật ký cập nhật v1.0.4:',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildUpdateBullet('Thẻ Sinh Viên Điện Tử (Digital ID Card) tích hợp QR cá nhân.'),
              _buildUpdateBullet('Chế độ Tối (Dark Mode) chuẩn OLED độ tương phản cao.'),
              _buildUpdateBullet('Đồng bộ hoạt động rèn luyện vào Google / Apple Calendar.'),
              _buildUpdateBullet('Khóa bảo mật ứng dụng bằng Face ID / Vân tay (App Lock).'),
              _buildUpdateBullet('Cải tiến quy trình Giấy xin phép & Khiếu nại trực tuyến.'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: AppColors.adaptiveTextSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi phiên làm việc hiện tại trên thiết bị này?',
          style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.adaptiveTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      await widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: AppColors.adaptiveAppBarBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Tài khoản & Cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _confirmAndLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && user == null
                ? _EmptyMessage(message: _errorMessage!, isError: true)
                : user == null
                    ? const _EmptyMessage(message: 'Chưa có dữ liệu hồ sơ.', isError: false)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
                          children: [
                            // 1. THẺ ĐẠI DIỆN SINH VIÊN VIP (HERO IDENTITY CARD)
                            _HeroStudentCard(
                              user: user,
                              avatarUpload: _avatarUpload,
                              onPickAvatar: _pickAvatar,
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(
                                message: _errorMessage!,
                                color: AppColors.danger,
                                icon: Icons.error_outline_rounded,
                              ),
                            ],
                            if (_successMessage != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(
                                message: _successMessage!,
                                color: const Color(0xFF059669),
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ],

                            const SizedBox(height: 20),

                            // 2. NHÓM 1: THÔNG TIN SINH VIÊN & LIÊN HỆ
                            _SectionGroup(
                              title: 'Hồ sơ học tập & Liên hệ',
                              icon: Icons.school_rounded,
                              action: TextButton.icon(
                                onPressed: () {
                                  setState(() => _isEditingContact = !_isEditingContact);
                                },
                                icon: Icon(
                                  _isEditingContact ? Icons.close_rounded : Icons.edit_note_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  _isEditingContact ? 'Đóng' : 'Cập nhật',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                ),
                              ),
                              children: [
                                _InfoTile(label: 'Mã số sinh viên', value: user.code, icon: Icons.badge_outlined),
                                _InfoTile(label: 'Họ và tên', value: user.name, icon: Icons.person_outline_rounded),
                                _InfoTile(label: 'Lớp sinh hoạt', value: user.studentClass, icon: Icons.class_outlined),
                                _InfoTile(label: 'Khoa / Viện', value: user.department, icon: Icons.account_balance_outlined),

                                Divider(height: 20, thickness: 0.6, color: AppColors.adaptiveBorder),

                                // Trạng thái đang chờ duyệt
                                if (_pendingRequest != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.isDark
                                          ? const Color(0xFF451A03).withValues(alpha: 0.35)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.isDark
                                            ? const Color(0xFFB45309).withValues(alpha: 0.5)
                                            : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 17),
                                            SizedBox(width: 8),
                                            Text(
                                              'Yêu cầu cập nhật đang chờ duyệt',
                                              style: TextStyle(
                                                color: Color(0xFF92400E),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Thời gian: ${_pendingRequest!['requested_at'] ?? 'Vừa xong'}',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                                        ),
                                        Text(
                                          'Email: ${_pendingRequest!['email']} • SĐT: ${_pendingRequest!['phone']}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF451A03), fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFFB45309),
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                            ),
                                            onPressed: _cancelProfileRequest,
                                            icon: const Icon(Icons.cancel_outlined, size: 16),
                                            label: const Text('Hủy yêu cầu này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                if (!_isEditingContact) ...[
                                  _InfoTile(label: 'Địa chỉ Email', value: user.email, icon: Icons.email_outlined),
                                  _InfoTile(label: 'Số điện thoại', value: user.phone, icon: Icons.phone_outlined),
                                  _InfoTile(label: 'Địa chỉ liên hệ', value: user.address, icon: Icons.home_outlined),
                                ] else ...[
                                  // Form cập nhật thông tin
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email liên hệ mới',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Số điện thoại mới',
                                      prefixIcon: const Icon(Icons.phone_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _addressController,
                                    decoration: InputDecoration(
                                      labelText: 'Địa chỉ liên hệ mới',
                                      prefixIcon: const Icon(Icons.home_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  PrimaryButton(
                                    label: 'Gửi yêu cầu xét duyệt',
                                    isLoading: _isSubmittingRequest,
                                    onPressed: _submitProfileChangeRequest,
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 18),

                            // 3. NHÓM 2: BẢO MẬT & ĐĂNG NHẬP
                            _SectionGroup(
                              title: 'Bảo mật tài khoản',
                              icon: Icons.shield_rounded,
                              children: [
                                // Nút bung mở Đổi mật khẩu
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      setState(() {
                                        _isPasswordSectionExpanded = !_isPasswordSectionExpanded;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Đổi mật khẩu qua OTP Email',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14.5,
                                                    color: AppColors.adaptiveTextPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  'Xác thực mã bảo mật gửi đến hộp thư sinh viên',
                                                  style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            _isPasswordSectionExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.adaptiveTextSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                if (_isPasswordSectionExpanded) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu mới',
                                      hintText: 'Tối thiểu 6 ký tự',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _passwordConfirmController,
                                    obscureText: _obscureConfirm,
                                    decoration: InputDecoration(
                                      labelText: 'Xác nhận mật khẩu mới',
                                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  if (!_otpSent) ...[
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(46),
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _isSendingOtp ? null : _sendPasswordOtp,
                                      icon: _isSendingOtp
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.mark_email_unread_rounded, size: 18),
                                      label: Text(
                                        _isSendingOtp ? 'Đang gửi mã...' : 'Gửi mã OTP về Email',
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 6),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              counterText: '',
                                              labelText: 'Mã OTP 6 số từ email',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: _otpCountdown > 0 || _isSendingOtp ? null : _sendPasswordOtp,
                                                child: Text(
                                                  _otpCountdown > 0 ? 'Gửi lại sau ${_otpCountdown}s' : 'Gửi lại mã OTP',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    PrimaryButton(
                                      label: 'Xác nhận đổi mật khẩu',
                                      isLoading: _isSavingPassword,
                                      onPressed: _changePassword,
                                    ),
                                  ],
                                ],

                                // Đăng nhập sinh trắc học
                                Divider(height: 24, thickness: 0.6, color: AppColors.adaptiveBorder),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF059669), size: 22),
                                  ),
                                  title: Text(
                                    'Vân tay & Face ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.adaptiveTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Mở khóa và đăng nhập app nhanh chóng',
                                    style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                                  ),
                                  value: _biometricEnabled,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: _toggleBiometric,
                                ),
                                Divider(height: 20, thickness: 0.6, color: AppColors.adaptiveBorder),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.security_rounded, color: Color(0xFF6366F1), size: 22),
                                  ),
                                  title: Text(
                                    'Khóa ứng dụng (App Lock)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.adaptiveTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Yêu cầu Face ID / Vân tay khi quay lại app',
                                    style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                                  ),
                                  value: _appLockEnabled,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: _toggleAppLock,
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // 4. NHÓM 3: TÙY CHỌN ỨNG DỤNG
                            _SectionGroup(
                              title: 'Trải nghiệm ứng dụng',
                              icon: Icons.tune_rounded,
                              children: [
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ThemeService.instance.isDarkMode
                                          ? const Color(0xFF818CF8).withValues(alpha: 0.15)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      ThemeService.instance.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                      color: ThemeService.instance.isDarkMode ? const Color(0xFF6366F1) : const Color(0xFFD97706),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    'Giao diện Tối (Dark Mode)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.adaptiveTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    ThemeService.instance.isDarkMode ? 'Đang bật nền tối' : 'Đang bật nền sáng',
                                    style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                                  ),
                                  value: ThemeService.instance.isDarkMode,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (_) async {
                                    await ThemeService.instance.toggleTheme();
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // 4B. NHÓM 4: HỖ TRỢ SINH VIÊN (PHÒNG CTSV)
                            _SectionGroup(
                              title: 'Hỗ trợ sinh viên (Phòng CTSV)',
                              icon: Icons.support_agent_rounded,
                              children: const [
                                _SupportContactRow(
                                  icon: Icons.location_on_outlined,
                                  text: 'Cơ sở 1: 287 Phan Đình Phùng, P.15, Q. Phú Nhuận, TP.HCM',
                                ),
                                SizedBox(height: 9),
                                _SupportContactRow(
                                  icon: Icons.location_on_outlined,
                                  text: 'Cơ sở 2: 12 Nguyễn Văn Bảo, P.4, Q. Gò Vấp, TP.HCM',
                                ),
                                SizedBox(height: 9),
                                _SupportContactRow(
                                  icon: Icons.phone_in_talk_outlined,
                                  text: 'Hotline: (028) 3844 6320 • (028) 3845 7440',
                                ),
                                SizedBox(height: 9),
                                _SupportContactRow(
                                  icon: Icons.mail_outline_rounded,
                                  text: 'Email: ctsv@cofer.edu.vn • ctsv.cofer@gmail.com',
                                ),
                                SizedBox(height: 9),
                                _SupportContactRow(
                                  icon: Icons.access_time_rounded,
                                  text: 'Giờ làm việc: Thứ 2 - Thứ 6 (7h30 - 11h30 | 13h00 - 17h00)',
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // 4C. NHÓM 5: HỎI ĐÁP THƯỜNG GẶP (FAQ)
                            const _SectionGroup(
                              title: 'Hỏi đáp thường gặp (FAQ)',
                              icon: Icons.help_outline_rounded,
                              children: [
                                _ProfileFaqTile(
                                  question: 'Khi nào hệ thống chốt Điểm rèn luyện học kỳ?',
                                  answer:
                                      'Hệ thống mở cổng tự đánh giá từ tuần 14 đến tuần 16 của học kỳ. Sau đó GVCN và Khoa sẽ duyệt điểm trong vòng 2 tuần trước khi có quyết định công nhận điểm chính thức từ Hiệu trưởng.',
                                ),
                                SizedBox(height: 8),
                                _ProfileFaqTile(
                                  question: 'Nếu tham gia hoạt động nhưng chưa được điểm danh thì sao?',
                                  answer:
                                      'Bạn hãy vào mục "Minh chứng" trên Trang chủ, tìm hoạt động đó và bấm "Gửi minh chứng" kèm ảnh chụp tại sự kiện để Ban tổ chức kiểm tra và cộng điểm bù.',
                                ),
                                SizedBox(height: 8),
                                _ProfileFaqTile(
                                  question: 'Tiêu chuẩn xếp loại điểm rèn luyện như thế nào?',
                                  answer:
                                      '• Xuất sắc: 90 - 100 điểm\n• Tốt: 80 - 89 điểm\n• Khá: 65 - 79 điểm\n• Trung bình: 50 - 64 điểm\n• Yếu: 35 - 49 điểm\n• Kém: dưới 35 điểm.',
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 5. NÚT ĐĂNG XUẤT THIẾT KẾ MỀM MẠI
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: BorderSide(
                                    color: AppColors.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                                    width: 1.2,
                                  ),
                                  backgroundColor: AppColors.isDark
                                      ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                                      : const Color(0xFFFEF2F2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _confirmAndLogout,
                                icon: const Icon(Icons.logout_rounded, size: 19),
                                label: const Text(
                                  'Đăng xuất tài khoản',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 6. THÔNG TIN PHIÊN BẢN ỨNG DỤNG & KIỂM TRA CẬP NHẬT
                            Center(
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: _checkUpdate,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.adaptiveCardSubtle,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.adaptiveBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'COne Mobile v1.0.4 • Build 2026.11',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.adaptiveTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.adaptiveTextSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: _checkUpdate,
                                    icon: const Icon(Icons.sync_rounded, size: 15, color: AppColors.primary),
                                    label: const Text(
                                      'Kiểm tra bản cập nhật mới',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hệ thống Quản lý Điểm rèn luyện Sinh viên',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.adaptiveTextSecondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

/// Thẻ Hero Profile Sinh viên với Avatar, Thông tin chính, Badge trạng thái
class _HeroStudentCard extends StatelessWidget {
  const _HeroStudentCard({
    required this.user,
    required this.avatarUpload,
    required this.onPickAvatar,
  });

  final ProfileUser user;
  final ProfileUpload? avatarUpload;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar tròn viền trắng & nút đổi ảnh
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatarUpload != null
                          ? Image.memory(
                              avatarUpload!.bytes,
                              fit: BoxFit.cover,
                              width: 76,
                              height: 76,
                            )
                          : (user.avatarUrl.isNotEmpty
                              ? Image.network(
                                  user.avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 76,
                                  height: 76,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white70,
                                    size: 42,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white70,
                                  size: 42,
                                )),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: onPickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Họ tên & MSSV
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                              SizedBox(width: 4),
                              Text(
                                'Đang học',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.name.isEmpty ? user.code : user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: ${user.code}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Hàng badge thông tin nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lớp học',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.studentClass.isNotEmpty ? user.studentClass : '-',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khoa quản lý',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.department.isNotEmpty ? user.department : '-',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => DigitalStudentIdCardModal.show(context, user),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Mở Thẻ Sinh Viên Số & Mã QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối phân nhóm chức năng dạng Grouped Card
class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.title,
    required this.icon,
    required this.children,
    this.action,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Dòng hiển thị thông tin kèm icon
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppColors.adaptiveTextSecondary),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner thông báo trạng thái thành công / thất bại
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.adaptiveTextSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.adaptiveTextPrimary,
              fontWeight: FontWeight.w600,
              height: 1.38,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileFaqTile extends StatelessWidget {
  const _ProfileFaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCardSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.adaptiveTextSecondary,
          title: Text(
            question,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.adaptiveTextPrimary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.adaptiveTextSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
