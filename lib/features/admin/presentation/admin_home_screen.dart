import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';
import 'admin_account_screen.dart';
import 'admin_activities_screen.dart';
import 'admin_appellation_registrations_screen.dart';
import 'admin_business_list_screen.dart';
import 'admin_drl_assessments_screen.dart';
import 'admin_service_modules_screen.dart';
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
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openAppellations() {
    setState(() => _selectedIndex = 1);
  }

  void _openDrl() {
    setState(() => _selectedIndex = 2);
  }

  void _openStudents() {
    _push(AdminStudentsScreen(service: _service));
  }

  void _openActivities() {
    _push(AdminActivitiesScreen(service: _service));
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

  void _openServiceModules() {
    _push(
      AdminServiceModulesScreen(
        title: 'Nghiệp vụ CTSV/QTC1',
        subtitle:
            'Hệ thống quản lý hoạt động và điểm rèn luyện đồng bộ dữ liệu thời gian thực.',
        modules: [
          AdminServiceModule(
            name: 'Quản lý khiếu nại',
            description: 'Danh sách, phản hồi và cập nhật trạng thái đơn.',
            icon: Icons.report_problem_outlined,
            api: '/mobile/admin/complaints',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Quản lý khiếu nại',
              path: '/mobile/admin/complaints',
              icon: Icons.report_problem_outlined,
              action: AdminBusinessAction.resolveComplaint,
            ),
          ),
          AdminServiceModule(
            name: 'Quản lý giấy xin phép',
            description: 'Duyệt hoặc từ chối giấy vắng, bù, miễn hoạt động.',
            icon: Icons.assignment_turned_in_outlined,
            api: '/mobile/admin/permission-requests',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Quản lý giấy xin phép',
              path: '/mobile/admin/permission-requests',
              icon: Icons.assignment_turned_in_outlined,
              action: AdminBusinessAction.approveRejectPermission,
            ),
          ),
          AdminServiceModule(
            name: 'Tài liệu/hồ sơ sinh viên',
            description: 'Xem, duyệt hoặc từ chối tài liệu và minh chứng.',
            icon: Icons.folder_copy_outlined,
            api: '/mobile/admin/documents',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Tài liệu sinh viên',
              path: '/mobile/admin/documents',
              icon: Icons.folder_copy_outlined,
              action: AdminBusinessAction.approveRejectDocument,
            ),
          ),
          AdminServiceModule(
            name: 'Trạng thái hồ sơ',
            description: 'Cập nhật trạng thái hồ sơ cá nhân và ghi chú xử lý.',
            icon: Icons.assignment_ind_outlined,
            api: '/mobile/admin/profile-statuses',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Trạng thái hồ sơ',
              path: '/mobile/admin/profile-statuses',
              icon: Icons.assignment_ind_outlined,
              action: AdminBusinessAction.updateProfileStatus,
            ),
          ),
          AdminServiceModule(
            name: 'Thông báo',
            description: 'Xem và gửi thông báo app cho sinh viên.',
            icon: Icons.notifications_active_outlined,
            api: '/mobile/admin/notifications',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Thông báo quản trị',
              path: '/mobile/admin/notifications',
              icon: Icons.notifications_active_outlined,
              action: AdminBusinessAction.sendNotification,
            ),
          ),
          AdminServiceModule(
            name: 'Tỷ lệ tham gia',
            description: 'Xem thống kê participation theo phạm vi tài khoản.',
            icon: Icons.query_stats_outlined,
            api: '/mobile/admin/participation-rate',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Tỷ lệ tham gia',
              path: '/mobile/admin/participation-rate',
              icon: Icons.query_stats_outlined,
            ),
          ),
          AdminServiceModule(
            name: 'Audit log',
            description: 'Xem lịch sử thao tác hệ thống.',
            icon: Icons.security_outlined,
            api: '/mobile/admin/audit-logs',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Audit log',
              path: '/mobile/admin/audit-logs',
              icon: Icons.security_outlined,
            ),
          ),
          AdminServiceModule(
            name: 'Backup hệ thống',
            description: 'Xem backup; tạo backup chỉ dành cho tài khoản level 0.',
            icon: Icons.backup_outlined,
            api: '/mobile/admin/backups',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Backup hệ thống',
              path: '/mobile/admin/backups',
              icon: Icons.backup_outlined,
              action: AdminBusinessAction.createBackup,
            ),
          ),
          const AdminServiceModule(
            name: 'QR code điểm danh',
            description:
                'Backend cần API chọn hoạt động/tạo QR/cập nhật hạn QR đầy đủ cho mobile.',
            icon: Icons.qr_code_2_outlined,
            api: '/mobile/admin/activities/{id}/qr-codes',
            ready: false,
          ),
          const AdminServiceModule(
            name: 'Cán bộ lớp',
            description:
                'Backend cần API danh sách lớp và CRUD cán bộ lớp để mobile thao tác trọn vẹn.',
            icon: Icons.groups_2_outlined,
            api: '/mobile/admin/class-officers',
            ready: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
    );
  }

  Widget _buildOverviewTab() {
    final admin = widget.session.admin;
    return Scaffold(
      appBar: AppBar(
        title: Text('CTSV: ${admin.name.isEmpty ? admin.email : admin.name}'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
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
                  isWide ? 32 : 18,
                  12,
                  isWide ? 32 : 18,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AdminCard(admin: admin),
                        const SizedBox(height: 22),
                        FutureBuilder<AdminDashboard>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: CircularProgressIndicator(),
                                ),
                              );
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
                                _StatsGrid(dashboard: dashboard, isWide: isWide),
                                const SizedBox(height: 26),
                                const SectionHeader(title: 'Quản trị nhanh'),
                                const SizedBox(height: 14),
                                GridView.count(
                                  crossAxisCount: isWide ? 3 : 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: isWide ? 1.2 : .98,
                                  children: [
                                    FeatureCard(
                                      title: 'Hồ sơ danh hiệu',
                                      subtitle: 'Xem đăng ký',
                                      icon: Icons.workspace_premium_outlined,
                                      color: AppColors.warning,
                                      onTap: _openAppellations,
                                    ),
                                    FeatureCard(
                                      title: 'Duyệt DRL',
                                      subtitle: 'Phiếu rèn luyện',
                                      icon: Icons.fact_check_outlined,
                                      color: AppColors.success,
                                      onTap: _openDrl,
                                    ),
                                    FeatureCard(
                                      title: 'Sinh viên khoa',
                                      subtitle: 'Danh sách theo phạm vi',
                                      icon: Icons.groups_2_outlined,
                                      color: AppColors.primary,
                                      onTap: _openStudents,
                                    ),
                                    FeatureCard(
                                      title: 'Hoạt động',
                                      subtitle: 'Danh sách hoạt động',
                                      icon: Icons.event_available_outlined,
                                      color: AppColors.purple,
                                      onTap: _openActivities,
                                    ),
                                    FeatureCard(
                                      title: 'Nghiệp vụ CTSV',
                                      subtitle: 'Đơn từ, hồ sơ, thống kê',
                                      icon: Icons.admin_panel_settings_outlined,
                                      color: AppColors.darkBlue,
                                      onTap: _openServiceModules,
                                    ),
                                  ],
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
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabNavigator(0, _buildOverviewTab()),
            _buildTabNavigator(
              1,
              AdminAppellationRegistrationsScreen(service: _service),
            ),
            _buildTabNavigator(
              2,
              AdminDrlAssessmentsScreen(service: _service),
            ),
            _buildTabNavigator(
              3,
              AdminAccountScreen(
                session: widget.session,
                onLogout: widget.onLogout,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (_selectedIndex == index) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Danh hiệu'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'DRL'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.admin});

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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name.isEmpty ? 'Phòng Công tác Sinh viên' : admin.name,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(admin.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.84))),
                const SizedBox(height: 8),
                Text(
                  '${admin.roleName} • ${admin.roleCode.toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.dashboard, required this.isWide});

  final AdminDashboard dashboard;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Sinh viên', dashboard.totalStudents, Icons.groups_2_outlined, AppColors.primary),
      ('Hoạt động', dashboard.totalActivities, Icons.event_available_outlined, AppColors.purple),
      ('Chờ danh hiệu', dashboard.pendingAppellations, Icons.workspace_premium_outlined, AppColors.warning),
      ('Chờ duyệt DRL', dashboard.pendingDrlAssessments, Icons.fact_check_outlined, AppColors.success),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.45 : 1.25,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return COneCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat.$3, color: stat.$4),
              Text(stat.$2.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              Text(
                stat.$1,
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Không tải được dữ liệu admin', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
