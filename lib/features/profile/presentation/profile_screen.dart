import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
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

  ProfileUser? _user;
  ProfileUpload? _avatarUpload;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.fetchProfile();
      _applyUser(data.user);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được hồ sơ cá nhân.');
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
    setState(() => _avatarUpload = ProfileUpload(name: file!.name, bytes: file.bytes!));
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSavingProfile = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final data = await widget.service.updateProfile(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        avatar: _avatarUpload,
      );
      _applyUser(data.user);
      setState(() => _successMessage = 'Đã cập nhật hồ sơ cá nhân.');
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không lưu được hồ sơ cá nhân.');
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _isSavingPassword = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.service.changePassword(
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );
      _passwordController.clear();
      _passwordConfirmController.clear();
      setState(() => _successMessage = 'Đổi mật khẩu thành công.');
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không đổi được mật khẩu.');
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
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
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        children: [
                          _ProfileHeader(user: user, avatarName: _avatarUpload?.name, onPickAvatar: _pickAvatar),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _Banner(message: _errorMessage!, color: AppColors.danger),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 12),
                            _Banner(message: _successMessage!, color: const Color(0xFF059669)),
                          ],
                          const SizedBox(height: 16),
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin liên hệ',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 14),
                                _ReadonlyInfo(label: 'MSSV', value: user.code),
                                _ReadonlyInfo(label: 'Họ tên', value: user.name),
                                _ReadonlyInfo(label: 'Lớp', value: user.studentClass),
                                _ReadonlyInfo(label: 'Khoa', value: user.department),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Số điện thoại',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Địa chỉ',
                                    prefixIcon: Icon(Icons.location_on_outlined),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Lưu thông tin',
                                  isLoading: _isSavingProfile,
                                  onPressed: _saveProfile,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Mật khẩu mới',
                                    prefixIcon: Icon(Icons.lock_outline_rounded),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordConfirmController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    prefixIcon: Icon(Icons.lock_reset_rounded),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Đổi mật khẩu',
                                  isLoading: _isSavingPassword,
                                  onPressed: _changePassword,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
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
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: user.avatarUrl.isEmpty ? null : NetworkImage(user.avatarUrl),
                child: user.avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: Colors.white, size: 36) : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  onPressed: onPickAvatar,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
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
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  avatarName == null ? '${user.code} • ${user.studentClass}' : 'Đã chọn: $avatarName',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
          ),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
