import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/theme_service.dart';
import '../data/admin_models.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AdminSession session;
  final Future<void> Function() onLogout;

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất tài khoản?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi cổng quản trị COne không?',
          style: TextStyle(color: AppColors.adaptiveTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.session.admin;
    final displayName = admin.name.isEmpty ? 'Tài khoản quản trị' : admin.name;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr('Tài khoản', 'Account'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.3,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. Thẻ định danh quản trị
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          admin.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${admin.roleName} • Level ${admin.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Thông tin chi tiết
            _AdminSectionCard(
              title: 'Thông tin quản trị',
              icon: Icons.badge_outlined,
              children: [
                _InfoRow(label: 'Họ tên', value: displayName),
                _InfoRow(label: 'Email', value: admin.email),
                _InfoRow(
                  label: 'Số điện thoại',
                  value: admin.phone.isEmpty ? 'Chưa cập nhật' : admin.phone,
                ),
                _InfoRow(
                  label: 'Vai trò',
                  value: '${admin.roleName} (${admin.roleCode.toUpperCase()})',
                ),
                _InfoRow(
                  label: 'Khoa / Đơn vị',
                  value: admin.departmentId.isEmpty
                      ? 'Toàn trường'
                      : admin.departmentId,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Giao diện & Ngôn ngữ
            _AdminSectionCard(
              title: tr('Giao diện & Ngôn ngữ', 'Appearance & Language'),
              icon: Icons.tune_rounded,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ThemeService.instance.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tr('Giao diện Tối (Dark Mode)', 'Dark Mode'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.adaptiveTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    ThemeService.instance.isDarkMode
                        ? tr('Đang bật nền tối', 'Dark theme enabled')
                        : tr('Đang bật nền sáng', 'Light theme enabled'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.adaptiveTextSecondary,
                    ),
                  ),
                  value: ThemeService.instance.isDarkMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) async {
                    await ThemeService.instance.toggleTheme();
                    if (mounted) setState(() {});
                  },
                ),
                Divider(height: 16, thickness: 0.6, color: AppColors.adaptiveBorder),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tr('Ngôn ngữ hiển thị', 'Display Language'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.adaptiveTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    LocaleService.instance.isEnglish
                        ? 'English (EN)'
                        : 'Tiếng Việt (VI)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.adaptiveTextSecondary,
                    ),
                  ),
                  trailing: const LanguageToggleChip(),
                  onTap: () async {
                    await LocaleService.instance.toggleLocale();
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 4. Nút đăng xuất
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.isDark
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFFFECACA),
                    width: 1.2,
                  ),
                  backgroundColor: AppColors.isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                      : const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: Text(
                  tr('Đăng xuất tài khoản', 'Sign Out'),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'COne Admin v1.0.4 • Hệ thống Quản lý Điểm rèn luyện',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adaptiveTextSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
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
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: AppColors.adaptiveBorder),
      ],
    );
  }
}
