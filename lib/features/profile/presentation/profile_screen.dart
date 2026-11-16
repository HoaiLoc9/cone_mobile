import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/auth_service.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';

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

  int _otpCountdown = 0;
  Timer? _countdownTimer;

  Map<String, dynamic>? _pendingRequest;

  String? _errorMessage;
  String? _successMessage;

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

      // Fetch pending request from backend API
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
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể tải thông tin hồ sơ.');
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
    setState(
      () => _avatarUpload = ProfileUpload(name: file!.name, bytes: file.bytes!),
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
            content: const Text(
              'Thông tin cá nhân của sinh viên cần được GVCN hoặc Ban cán sự kiểm tra và phê duyệt trước khi cập nhật chính thức.\n\nBạn có muốn gửi yêu cầu thay đổi thông tin này không?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
        _successMessage =
            'Đã gửi yêu cầu thay đổi thông tin thành công! Yêu cầu đang được chờ phê duyệt.';
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
      _passwordController.clear();
      _passwordConfirmController.clear();
      _otpController.clear();
      _countdownTimer?.cancel();
      setState(() {
        _otpSent = false;
        _otpCountdown = 0;
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

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Hồ sơ sinh viên',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
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
                ? _Message(message: _errorMessage!, isError: true)
                : user == null
                    ? const _Message(message: 'Chưa có dữ liệu hồ sơ.', isError: false)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                        children: [
                          _ProfileHeader(
                            user: user,
                            avatarName: _avatarUpload?.name,
                            onPickAvatar: _pickAvatar,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _Banner(message: _errorMessage!, color: AppColors.danger, icon: Icons.error_outline_rounded),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 14),
                            _Banner(message: _successMessage!, color: const Color(0xFF059669), icon: Icons.check_circle_outline_rounded),
                          ],
                          const SizedBox(height: 16),

                          // Profile update card with approval flow
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Thông tin liên hệ & Hồ sơ',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _ReadonlyInfo(label: 'Mã sinh viên', value: user.code),
                                _ReadonlyInfo(label: 'Họ và tên', value: user.name),
                                _ReadonlyInfo(label: 'Lớp sinh hoạt', value: user.studentClass),
                                _ReadonlyInfo(label: 'Khoa / Viện', value: user.department),
                                const Divider(height: 24, thickness: 0.8),

                                // Pending approval banner if active
                                if (_pendingRequest != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Yêu cầu thay đổi đang chờ duyệt',
                                              style: TextStyle(
                                                color: Color(0xFF92400E),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Thời gian gửi: ${_pendingRequest!['requested_at'] ?? 'Vừa xong'}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email mới: ${_pendingRequest!['email']}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF451A03), fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          'SĐT mới: ${_pendingRequest!['phone']}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF451A03), fontWeight: FontWeight.w700),
                                        ),
                                        if ((_pendingRequest!['address'] ?? '').isNotEmpty)
                                          Text(
                                            'Địa chỉ: ${_pendingRequest!['address']}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF451A03), fontWeight: FontWeight.w700),
                                          ),
                                        const SizedBox(height: 10),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFB45309),
                                            side: const BorderSide(color: Color(0xFFFBBF24)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: _cancelProfileRequest,
                                          icon: const Icon(Icons.close_rounded, size: 16),
                                          label: const Text('Hủy yêu cầu này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Địa chỉ Email',
                                    hintText: 'Nhập email liên hệ',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Số điện thoại',
                                    hintText: 'Nhập số điện thoại',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Địa chỉ hiện tại',
                                    hintText: 'Nhập nơi ở / liên lạc',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: _pendingRequest != null
                                      ? 'Gửi yêu cầu thay đổi mới'
                                      : 'Gửi yêu cầu thay đổi thông tin',
                                  isLoading: _isSubmittingRequest,
                                  onPressed: _submitProfileChangeRequest,
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text(
                                    'Thông tin thay đổi sẽ được gửi đến GVCN phê duyệt trước khi lưu.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Password Change card with Email OTP
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyan.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Đổi mật khẩu qua OTP Email',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Mã xác thực bảo mật sẽ được gửi đến hộp thư: ${user.email.isNotEmpty ? user.email : "Email sinh viên"}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordConfirmController,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu mới',
                                    hintText: 'Nhập lại mật khẩu mới',
                                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // OTP Request or Verify Section
                                if (!_otpSent) ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _isSendingOtp ? null : _sendPasswordOtp,
                                    icon: _isSendingOtp
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.mark_email_unread_rounded),
                                    label: Text(
                                      _isSendingOtp ? 'Đang gửi mã OTP...' : 'Gửi mã OTP về Email',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Đã gửi mã xác thực',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Kiểm tra hòm thư ${user.email} (bao gồm cả thư rác/spam).',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _otpController,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 6,
                                          ),
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            counterText: '',
                                            labelText: 'Mã xác thực OTP 6 số',
                                            hintText: '______',
                                            prefixIcon: const Icon(Icons.key_rounded),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton.icon(
                                              onPressed: _otpCountdown > 0 || _isSendingOtp ? null : _sendPasswordOtp,
                                              icon: const Icon(Icons.refresh_rounded, size: 16),
                                              label: Text(
                                                _otpCountdown > 0
                                                    ? 'Gửi lại sau ${_otpCountdown}s'
                                                    : 'Gửi lại mã OTP',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  PrimaryButton(
                                    label: 'Xác nhận đổi mật khẩu',
                                    isLoading: _isSavingPassword,
                                    onPressed: _changePassword,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Nút Đăng xuất to bản ở cuối trang
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                                backgroundColor: const Color(0xFFFEF2F2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _confirmAndLogout,
                              icon: const Icon(Icons.logout_rounded, size: 20),
                              label: const Text(
                                'ĐĂNG XUẤT TÀI KHOẢN',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi phiên làm việc hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.avatarName,
    required this.onPickAvatar,
  });

  final ProfileUser user;
  final String? avatarName;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: user.avatarUrl.isEmpty ? null : NetworkImage(user.avatarUrl),
                child: user.avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: Colors.white, size: 38) : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onPickAvatar,
                  icon: const Icon(Icons.camera_alt_rounded, size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? user.code : user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  avatarName == null ? '${user.code} • ${user.studentClass}' : 'Đã chọn ảnh: $avatarName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyInfo extends StatelessWidget {
  const _ReadonlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

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
            color: isError ? AppColors.danger : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
