import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/services/theme_service.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/smooth_page_route.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';
import 'admin_business_list_screen.dart';
import 'gvcn_drl_assessments_screen.dart';

class GvcnHomeScreen extends StatefulWidget {
  const GvcnHomeScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AdminSession session;
  final Future<void> Function() onLogout;

  @override
  State<GvcnHomeScreen> createState() => _GvcnHomeScreenState();
}

class _GvcnHomeScreenState extends State<GvcnHomeScreen> {
  late final AdminService _service = AdminService(token: widget.session.token);
  late Future<AdminDashboard> _future = _service.gvcnDashboard();

  void _reload() => setState(() => _future = _service.gvcnDashboard());

  void _push(Widget screen) {
    Navigator.of(context).push(SmoothPageRoute(builder: (_) => screen));
  }

  void _openDrl({String status = ''}) {
    _push(GvcnDrlAssessmentsScreen(service: _service, initialStatus: status));
  }

  void _openBusinessList({
    required String title,
    required String path,
    required IconData icon,
    AdminBusinessAction action = AdminBusinessAction.none,
  }) {
    _push(
      AdminBusinessListScreen(
        service: _service,
        title: title,
        path: path,
        icon: icon,
        action: action,
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

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
          'Bạn có chắc chắn muốn đăng xuất khỏi cổng GVCN không?',
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
    final displayName = admin.name.isEmpty ? 'Giáo viên chủ nhiệm' : admin.name;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
            Text(
              'COne • Cổng Giáo viên chủ nhiệm',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chế độ sáng / tối',
            onPressed: () async {
              await ThemeService.instance.toggleTheme();
              if (mounted) setState(() {});
            },
            icon: Icon(
              ThemeService.instance.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: AppColors.adaptiveTextPrimary,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextPrimary, size: 20),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<AdminDashboard>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SingleChildScrollView(
                  child: ShimmerListLoading(itemCount: 4),
                );
              }
              if (snapshot.hasError) {
                return _StateMessage(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final dashboard = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 16,
                      10,
                      isWide ? 28 : 16,
                      28,
                    ),
                    children: [
                      // 1. Thẻ GVCN (COne Blue)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
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
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    admin.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.82),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      admin.roleName.isEmpty ? 'Giáo viên chủ nhiệm' : admin.roleName,
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
                      const SizedBox(height: 16),

                      // 2. Thẻ chỉ số lớp gọn 1 khối
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.adaptiveCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.adaptiveBorder),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _kpiCell('${dashboard.totalStudents}', 'Sinh viên', () => _openDrl()),
                              VerticalDivider(width: 1, color: AppColors.adaptiveBorder),
                              _kpiCell(
                                '${dashboard.pendingDrlAssessments}',
                                'Chưa duyệt',
                                () => _openDrl(status: 'pending'),
                                highlight: dashboard.pendingDrlAssessments > 0,
                              ),
                              VerticalDivider(width: 1, color: AppColors.adaptiveBorder),
                              _kpiCell(
                                '${dashboard.approvedDrlAssessments}',
                                'Đã duyệt',
                                () => _openDrl(status: 'approved'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Quản lý ĐRL lớp
                      Text(
                        'Quản lý điểm rèn luyện',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: isWide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: isWide ? 2.4 : 2.05,
                        children: [
                          _GvcnCard(
                            title: 'Chưa duyệt',
                            subtitle: '${dashboard.pendingDrlAssessments} phiếu',
                            icon: Icons.pending_actions_rounded,
                            onTap: () => _openDrl(status: 'pending'),
                          ),
                          _GvcnCard(
                            title: 'Đã duyệt',
                            subtitle: '${dashboard.approvedDrlAssessments} phiếu',
                            icon: Icons.verified_rounded,
                            onTap: () => _openDrl(status: 'approved'),
                          ),
                          _GvcnCard(
                            title: 'Tất cả phiếu',
                            subtitle: 'Nhập điểm & duyệt',
                            icon: Icons.fact_check_rounded,
                            onTap: _openDrl,
                          ),
                          _GvcnCard(
                            title: 'Giấy xin phép',
                            subtitle: 'Duyệt đơn lớp',
                            icon: Icons.assignment_turned_in_rounded,
                            onTap: () => _openBusinessList(
                              title: 'Giấy xin phép lớp',
                              path: '/mobile/admin/gvcn/permission-requests',
                              icon: Icons.assignment_turned_in_outlined,
                              action: AdminBusinessAction.gvcnApproveRejectPermission,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Nghiệp vụ lớp khác (thanh trượt tròn kiểu Messenger)
                      Text(
                        'Hồ sơ & Minh chứng lớp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 104,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          children: [
                            _circleItem(
                              Icons.folder_copy_outlined,
                              'Tài liệu lớp',
                              () => _openBusinessList(
                                title: 'Tài liệu lớp chủ nhiệm',
                                path: '/mobile/admin/gvcn/documents',
                                icon: Icons.folder_copy_outlined,
                              ),
                            ),
                            _circleItem(
                              Icons.assignment_ind_outlined,
                              'Hồ sơ SV',
                              () => _openBusinessList(
                                title: 'Trạng thái hồ sơ lớp',
                                path: '/mobile/admin/gvcn/profile-statuses',
                                icon: Icons.assignment_ind_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kpiCell(
    String value,
    String label,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: highlight ? AppColors.primary : AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adaptiveTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleItem(IconData icon, String label, VoidCallback onTap) {
    final isDark = AppColors.isDark;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : const Color(0xFFBFDBFE),
                    width: 1.3,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GvcnCard extends StatelessWidget {
  const _GvcnCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.adaptiveBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.adaptiveTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorView.fromError(
      message,
      fallbackTitle: 'Không tải được dữ liệu lớp chủ nhiệm',
      onRetry: onRetry,
    );
  }
}
