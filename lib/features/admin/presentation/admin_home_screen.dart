import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/smooth_page_route.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';
import 'admin_account_screen.dart';
import 'admin_activities_screen.dart';
import 'admin_appellation_registrations_screen.dart';
import 'admin_business_list_screen.dart';
import 'admin_drl_assessments_screen.dart';
import 'admin_students_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AdminSession session;
  final Future<void> Function() onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminService _service = AdminService(token: widget.session.token);
  late Future<AdminDashboard> _future = _service.dashboard();
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _reload() => setState(() => _future = _service.dashboard());

  void _push(Widget screen) {
    _navigatorKeys[_selectedIndex].currentState?.push(
      SmoothPageRoute(builder: (_) => screen),
    );
  }

  void _openAppellations() => setState(() => _selectedIndex = 1);
  void _openDrl() => setState(() => _selectedIndex = 2);
  void _openStudents() => _push(AdminStudentsScreen(service: _service));
  void _openActivities() => _push(AdminActivitiesScreen(service: _service));

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

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  Widget _buildOverviewTab() {
    final admin = widget.session.admin;
    final displayName = admin.name.isEmpty ? 'Phòng CTSV' : admin.name;

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
              'COne • Cổng Quản trị CTSV',
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
            tooltip: 'Làm mới',
            onPressed: _reload,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.adaptiveCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.adaptiveBorder),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isWide ? 28 : 16,
                  10,
                  isWide ? 28 : 16,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Thẻ Quản trị viên (COne Blue)
                        _AdminHeroCard(
                          name: displayName,
                          email: admin.email,
                          roleLabel: '${admin.roleName} • ${admin.roleCode.toUpperCase()}',
                        ),
                        const SizedBox(height: 16),

                        // 2. Chỉ số tổng quan + Chức năng
                        FutureBuilder<AdminDashboard>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const ShimmerListLoading(itemCount: 3);
                            }
                            if (snapshot.hasError) {
                              return _ErrorCard(
                                message: snapshot.error.toString(),
                                onRetry: _reload,
                              );
                            }
                            final dashboard = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thẻ 4 chỉ số KPI gọn 1 khối (bấm được vào từng mục)
                                _CompactAdminKpiCard(
                                  dashboard: dashboard,
                                  onStudents: _openStudents,
                                  onActivities: _openActivities,
                                  onAppellations: _openAppellations,
                                  onDrl: _openDrl,
                                ),
                                const SizedBox(height: 20),

                                // 4 chức năng quản trị chính (2x2 đồng bộ màu xanh COne)
                                Text(
                                  'Quản trị chính',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.adaptiveTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: isWide ? 4 : 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: isWide ? 2.4 : 2.05,
                                  children: [
                                    _AdminActionCard(
                                      title: 'Duyệt ĐRL',
                                      subtitle: '${dashboard.pendingDrlAssessments} phiếu chờ',
                                      icon: Icons.fact_check_rounded,
                                      onTap: _openDrl,
                                    ),
                                    _AdminActionCard(
                                      title: 'Danh hiệu',
                                      subtitle: '${dashboard.pendingAppellations} hồ sơ chờ',
                                      icon: Icons.workspace_premium_rounded,
                                      onTap: _openAppellations,
                                    ),
                                    _AdminActionCard(
                                      title: 'Sinh viên',
                                      subtitle: '${dashboard.totalStudents} sinh viên',
                                      icon: Icons.groups_rounded,
                                      onTap: _openStudents,
                                    ),
                                    _AdminActionCard(
                                      title: 'Hoạt động',
                                      subtitle: '${dashboard.totalActivities} hoạt động',
                                      icon: Icons.event_available_rounded,
                                      onTap: _openActivities,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),

                                // Thanh trượt ngang hình tròn kiểu Messenger — Nghiệp vụ CTSV
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Nghiệp vụ CTSV',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.adaptiveTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Trượt ngang →',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.adaptiveTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 104,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    children: [
                                      _AdminCircleAction(
                                        icon: Icons.report_problem_outlined,
                                        label: 'Khiếu nại',
                                        onTap: () => _openBusinessList(
                                          title: 'Quản lý khiếu nại',
                                          path: '/mobile/admin/complaints',
                                          icon: Icons.report_problem_outlined,
                                          action: AdminBusinessAction.resolveComplaint,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.assignment_turned_in_outlined,
                                        label: 'Giấy xin phép',
                                        onTap: () => _openBusinessList(
                                          title: 'Quản lý giấy xin phép',
                                          path: '/mobile/admin/permission-requests',
                                          icon: Icons.assignment_turned_in_outlined,
                                          action: AdminBusinessAction.approveRejectPermission,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.folder_copy_outlined,
                                        label: 'Tài liệu SV',
                                        onTap: () => _openBusinessList(
                                          title: 'Tài liệu sinh viên',
                                          path: '/mobile/admin/documents',
                                          icon: Icons.folder_copy_outlined,
                                          action: AdminBusinessAction.approveRejectDocument,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.assignment_ind_outlined,
                                        label: 'Hồ sơ SV',
                                        onTap: () => _openBusinessList(
                                          title: 'Trạng thái hồ sơ',
                                          path: '/mobile/admin/profile-statuses',
                                          icon: Icons.assignment_ind_outlined,
                                          action: AdminBusinessAction.updateProfileStatus,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.notifications_active_outlined,
                                        label: 'Gửi thông báo',
                                        onTap: () => _openBusinessList(
                                          title: 'Thông báo quản trị',
                                          path: '/mobile/admin/notifications',
                                          icon: Icons.notifications_active_outlined,
                                          action: AdminBusinessAction.sendNotification,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.query_stats_outlined,
                                        label: 'Tỷ lệ tham gia',
                                        onTap: () => _openBusinessList(
                                          title: 'Tỷ lệ tham gia',
                                          path: '/mobile/admin/participation-rate',
                                          icon: Icons.query_stats_outlined,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.security_outlined,
                                        label: 'Audit log',
                                        onTap: () => _openBusinessList(
                                          title: 'Audit log',
                                          path: '/mobile/admin/audit-logs',
                                          icon: Icons.security_outlined,
                                        ),
                                      ),
                                      _AdminCircleAction(
                                        icon: Icons.backup_outlined,
                                        label: 'Backup',
                                        onTap: () => _openBusinessList(
                                          title: 'Backup hệ thống',
                                          path: '/mobile/admin/backups',
                                          icon: Icons.backup_outlined,
                                          action: AdminBusinessAction.createBackup,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final currentNav = _navigatorKeys[_selectedIndex].currentState;
          if (currentNav != null && currentNav.canPop()) {
            currentNav.pop();
            return;
          }
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return;
          }
        },
        child: LazyTabStack(
          currentIndex: _selectedIndex,
          tabBuilders: [
            () => _buildTabNavigator(0, _buildOverviewTab()),
            () => _buildTabNavigator(
                  1,
                  AdminAppellationRegistrationsScreen(service: _service),
                ),
            () => _buildTabNavigator(
                  2,
                  AdminDrlAssessmentsScreen(service: _service),
                ),
            () => _buildTabNavigator(
                  3,
                  AdminAccountScreen(
                    session: widget.session,
                    onLogout: widget.onLogout,
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex == index) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.name,
    required this.email,
    required this.roleLabel,
  });

  final String name;
  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
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
                    roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _CompactAdminKpiCard extends StatelessWidget {
  const _CompactAdminKpiCard({
    required this.dashboard,
    required this.onStudents,
    required this.onActivities,
    required this.onAppellations,
    required this.onDrl,
  });

  final AdminDashboard dashboard;
  final VoidCallback onStudents;
  final VoidCallback onActivities;
  final VoidCallback onAppellations;
  final VoidCallback onDrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _kpiCell('${dashboard.totalStudents}', 'Sinh viên', onStudents),
            VerticalDivider(width: 1, color: AppColors.adaptiveBorder),
            _kpiCell('${dashboard.totalActivities}', 'Hoạt động', onActivities),
            VerticalDivider(width: 1, color: AppColors.adaptiveBorder),
            _kpiCell(
              '${dashboard.pendingAppellations}',
              'Chờ DH',
              onAppellations,
              highlight: dashboard.pendingAppellations > 0,
            ),
            VerticalDivider(width: 1, color: AppColors.adaptiveBorder),
            _kpiCell(
              '${dashboard.pendingDrlAssessments}',
              'Chờ ĐRL',
              onDrl,
              highlight: dashboard.pendingDrlAssessments > 0,
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: highlight ? AppColors.primary : AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
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
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
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

class _AdminCircleAction extends StatelessWidget {
  const _AdminCircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 72,
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

class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        border: Border(
          top: BorderSide(color: AppColors.adaptiveBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.dashboard_rounded, 'Tổng quan'),
              _item(1, Icons.workspace_premium_rounded, 'Danh hiệu'),
              _item(2, Icons.fact_check_rounded, 'Duyệt ĐRL'),
              _item(3, Icons.person_rounded, 'Tài khoản'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final active = currentIndex == index;
    final color = active ? AppColors.primary : AppColors.adaptiveTextSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không tải được dữ liệu quản trị',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
