import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/feature_card.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';
import 'admin_business_list_screen.dart';
import 'admin_service_modules_screen.dart';
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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

  void _openClassServices() {
    _push(
      AdminServiceModulesScreen(
        title: 'Nghiệp vụ GVCN',
        subtitle:
            'Dữ liệu được lọc theo lớp chủ nhiệm từ API mobile Laravel.',
        modules: [
          AdminServiceModule(
            name: 'Duyệt giấy xin phép',
            description:
                'Xem, duyệt hoặc từ chối giấy xin phép của sinh viên trong lớp.',
            icon: Icons.assignment_turned_in_outlined,
            api: '/mobile/admin/gvcn/permission-requests',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Giấy xin phép lớp',
              path: '/mobile/admin/gvcn/permission-requests',
              icon: Icons.assignment_turned_in_outlined,
              action: AdminBusinessAction.gvcnApproveRejectPermission,
            ),
          ),
          AdminServiceModule(
            name: 'Minh chứng/tài liệu',
            description: 'Xem tài liệu sinh viên thuộc lớp chủ nhiệm.',
            icon: Icons.folder_copy_outlined,
            api: '/mobile/admin/gvcn/documents',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Tài liệu lớp chủ nhiệm',
              path: '/mobile/admin/gvcn/documents',
              icon: Icons.folder_copy_outlined,
            ),
          ),
          AdminServiceModule(
            name: 'Trạng thái hồ sơ',
            description: 'Theo dõi trạng thái hồ sơ sinh viên trong lớp.',
            icon: Icons.assignment_ind_outlined,
            api: '/mobile/admin/gvcn/profile-statuses',
            ready: true,
            onTap: () => _openBusinessList(
              title: 'Trạng thái hồ sơ lớp',
              path: '/mobile/admin/gvcn/profile-statuses',
              icon: Icons.assignment_ind_outlined,
            ),
          ),
          AdminServiceModule(
            name: 'Duyệt DRL',
            description: 'Màn nhập/lưu cột GVCN, duyệt và gỡ duyệt phiếu DRL.',
            icon: Icons.fact_check_outlined,
            api: '/mobile/admin/gvcn/drl-assessments',
            ready: true,
            onTap: _openDrl,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.session.admin;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GVCN: ${admin.name.isEmpty ? admin.email : admin.name}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
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
          child: FutureBuilder<AdminDashboard>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
                    padding: EdgeInsets.all(isWide ? 28 : 18),
                    children: [
                      _HeaderCard(admin: admin),
                      const SizedBox(height: 18),
                      _StatsGrid(dashboard: dashboard, isWide: isWide),
                      const SizedBox(height: 24),
                      const Text(
                        'Quản lý lớp',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: isWide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: isWide ? 1.45 : 1.05,
                        children: [
                          FeatureCard(
                            title: 'Phiếu chưa duyệt',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => _openDrl(status: 'pending'),
                          ),
                          FeatureCard(
                            title: 'Phiếu đã duyệt',
                            icon: Icons.verified_outlined,
                            color: const Color(0xFF059669),
                            onTap: () => _openDrl(status: 'approved'),
                          ),
                          FeatureCard(
                            title: 'Tất cả phiếu DRL',
                            icon: Icons.fact_check_outlined,
                            color: AppColors.primary,
                            onTap: _openDrl,
                          ),
                          FeatureCard(
                            title: 'Giấy phép & hồ sơ',
                            subtitle: 'Lọc theo lớp chủ nhiệm',
                            icon: Icons.folder_shared_outlined,
                            color: AppColors.darkBlue,
                            onTap: _openClassServices,
                          ),
                        ],
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
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.admin});

  final AdminUser admin;

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
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
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
            child: const Icon(Icons.school_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name.isEmpty ? 'Giáo viên chủ nhiệm' : admin.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  style: TextStyle(color: Colors.white.withValues(alpha: .84)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lớp phụ trách: ${admin.classId.isEmpty ? 'chưa gán' : admin.classId}',
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.dashboard, required this.isWide});

  final AdminDashboard dashboard;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Sinh viên', dashboard.totalStudents, Icons.groups_2_outlined),
      ('Chờ duyệt', dashboard.pendingDrlAssessments, Icons.pending_outlined),
      ('Đã duyệt', dashboard.approvedDrlAssessments, Icons.verified_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.9 : 3.4,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBlue.withValues(alpha: .07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(stat.$3, color: AppColors.primary, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  stat.$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                stat.$2.toString(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
