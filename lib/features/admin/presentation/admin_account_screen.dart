import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/cone_card.dart';
import '../data/admin_models.dart';

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AdminSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final admin = session.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài khoản quản trị',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _HeaderCard(admin: admin),
            const SizedBox(height: 16),
            COneCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Họ tên',
                    value: admin.name.isEmpty ? 'Chưa cập nhật' : admin.name,
                  ),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: admin.email,
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: admin.phone.isEmpty ? 'Chưa cập nhật' : admin.phone,
                  ),
                  _InfoRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Vai trò',
                    value: '${admin.roleName} (${admin.roleCode})',
                  ),
                  _InfoRow(
                    icon: Icons.layers_outlined,
                    label: 'Level',
                    value: admin.level.toString(),
                  ),
                  _InfoRow(
                    icon: Icons.apartment_outlined,
                    label: 'Khoa/đơn vị',
                    value: admin.departmentId.isEmpty
                        ? 'Toàn trường / chưa gán'
                        : admin.departmentId,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.admin});

  final AdminUser admin;

  @override
  Widget build(BuildContext context) {
    return COneCard(
      padding: const EdgeInsets.all(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.darkBlue, AppColors.primary],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name.isEmpty ? 'Tài khoản quản trị' : admin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: .84)),
                ),
                const SizedBox(height: 8),
                Text(
                  admin.roleName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
