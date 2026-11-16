import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../activity_support/data/activity_support_service.dart';
import '../../activity_support/presentation/missing_attendance_screen.dart';
import '../../activities/data/activity_service.dart';
import '../../activities/presentation/activity_list_screen.dart';
import '../../activities/presentation/registered_activities_screen.dart';
import '../../appellations/data/appellation_service.dart';
import '../../appellations/presentation/appellation_list_screen.dart';
import '../../auth/data/auth_service.dart';
import '../../chatbot/data/chatbot_service.dart';
import '../../chatbot/presentation/chatbot_screen.dart';
import '../../chatbot/presentation/cute_ai_robot_widget.dart';
import '../../drl/data/drl_models.dart';
import '../../drl/data/drl_service.dart';
import '../../drl/presentation/drl_summary_screen.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/presentation/notification_list_screen.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../qr_scan/data/qr_scan_service.dart';
import '../../qr_scan/presentation/qr_scan_screen.dart';
import '../../student_services/data/student_services_service.dart';
import '../../student_services/presentation/student_service_screens.dart';
import 'student_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session, required this.onLogout});

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthSession _session;
  late final DrlService _drlService;
  late final NotificationService _notificationService;
  late final StudentServicesService _studentServicesService;
  late Future<_StudentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _drlService = DrlService(token: _session.token);
    _notificationService = NotificationService(token: _session.token);
    _studentServicesService = StudentServicesService(token: _session.token);
    _dashboardFuture = _loadDashboard();
  }

  Future<_StudentDashboardData> _loadDashboard() async {
    final results = await Future.wait<Object>([
      _drlService.fetchSummary(),
      _notificationService.fetchUnreadCount(),
    ]);
    return _StudentDashboardData(
      summary: results[0] as DrlSummary,
      unreadNotifications: results[1] as int,
    );
  }

  void _reloadDashboard() {
    setState(() => _dashboardFuture = _loadDashboard());
  }

  void _openActivities() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ActivityListScreen(service: ActivityService(token: _session.token)),
      ),
    );
  }

  void _openRegisteredActivities() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisteredActivitiesScreen(
          service: ActivityService(token: _session.token),
        ),
      ),
    );
  }

  void _openStudentStats() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentStatsScreen(
          drlService: _drlService,
          activityService: ActivityService(token: _session.token),
          notificationService: _notificationService,
        ),
      ),
    );
  }

  void _openQrScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QrScanScreen(service: QrScanService(token: _session.token)),
      ),
    );
  }

  void _openDrl() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DrlSummaryScreen(service: _drlService)),
    );
  }

  void _openEvidence() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissingAttendanceScreen(
          service: ActivitySupportService(token: _session.token),
        ),
      ),
    );
  }

  void _openAppellations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppellationListScreen(
          service: AppellationService(token: _session.token),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationListScreen(service: _notificationService),
      ),
    );
  }

  void _openChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatbotScreen(service: ChatbotService(token: _session.token)),
      ),
    );
  }

  void _openComplaints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplaintsScreen(service: _studentServicesService),
      ),
    );
  }

  void _openPermissionRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PermissionRequestsScreen(service: _studentServicesService),
      ),
    );
  }

  void _openDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentsScreen(service: _studentServicesService),
      ),
    );
  }

  void _openProfileStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileStatusScreen(service: _studentServicesService),
      ),
    );
  }

  void _openCv() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CvScreen(service: _studentServicesService),
      ),
    );
  }

  void _openActivitySuggestions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ActivitySuggestionsScreen(service: _studentServicesService),
      ),
    );
  }

  void _openSignatureRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SignatureRequestsScreen(service: _studentServicesService),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          service: ProfileService(token: _session.token),
          session: _session,
          onLogout: widget.onLogout,
          onProfileUpdated: (profileUser) {
            setState(() {
              _session = AuthSession(
                token: _session.token,
                user: profileUser.toStudentUser(),
              );
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.user;
    final displayName = user.name.isEmpty ? user.code : user.name;

    return AppShell(
      title: 'Xin chào, $displayName',
      subtitle: 'COne • Hệ thống rèn luyện sinh viên',
      floatingActionButton: CuteAiRobotWidget(
        onTap: _openChatbot,
        greetingText: 'Hỏi AI nhé! ✨',
      ),
      actions: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: _openNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _reloadDashboard,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Tài khoản',
          onPressed: _openProfile,
          icon: const Icon(Icons.account_circle_outlined, size: 26),
        ),
      ],
      body: Stack(
        children: [
          // Quả cầu ánh sáng 3D nền (Ambient Glow Orbs)
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.10),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async => _reloadDashboard(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Student3DCard(session: _session, onQrTap: _openQrScan),
                      const SizedBox(height: 20),
                      FutureBuilder<_StudentDashboardData>(
                        future: _dashboardFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _DashboardSkeleton(isWide: isWide);
                          }
                          if (snapshot.hasError) {
                            return _DashboardFallback(
                              message: snapshot.error.toString(),
                              profileStatus: _profileStatusLabel(user),
                              onRetry: _reloadDashboard,
                            );
                          }
                          return _Dashboard3DGrid(
                            data: snapshot.data!,
                            profileStatus: _profileStatusLabel(user),
                            isWide: isWide,
                            onDrlTap: _openDrl,
                            onNotificationsTap: _openNotifications,
                            onProfileTap: _openProfile,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _AnimatedAiSuggestionBanner(
                        onTap: _openActivitySuggestions,
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(
                        title: 'Tiện ích hệ thống',
                      ),
                      const SizedBox(height: 14),
                      _QuickAction3DGrid(
                        isWide: isWide,
                        onActivities: _openActivities,
                        onRegisteredActivities: _openRegisteredActivities,
                        onStats: _openStudentStats,
                        onDrl: _openDrl,
                        onEvidence: _openEvidence,
                        onAppellations: _openAppellations,
                        onQr: _openQrScan,
                        onNotifications: _openNotifications,
                        onChatbot: _openChatbot,
                        onComplaints: _openComplaints,
                        onPermissionRequests: _openPermissionRequests,
                        onDocuments: _openDocuments,
                        onProfileStatus: _openProfileStatus,
                        onCv: _openCv,
                        onActivitySuggestions: _openActivitySuggestions,
                        onSignatureRequests: _openSignatureRequests,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _profileStatusLabel(dynamic user) {
    final missing = [
      user.code,
      user.name,
      user.email,
      user.studentClass,
      user.department,
    ].where((value) => value.toString().trim().isEmpty).length;
    if (missing == 0) return 'Đầy đủ';
    if (missing <= 2) return 'Cần bổ sung';
    return 'Thiếu thông tin';
  }
}

class _StudentDashboardData {
  const _StudentDashboardData({
    required this.summary,
    required this.unreadNotifications,
  });

  final DrlSummary summary;
  final int unreadNotifications;
}

// -------------------------------------------------------------
// 1. THẺ SINH VIÊN 3D HOLOGRAPHIC VIP CARD
// -------------------------------------------------------------
class _Student3DCard extends StatelessWidget {
  const _Student3DCard({required this.session, required this.onQrTap});

  final AuthSession session;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final studentName = user.name.isEmpty ? 'SINH VIÊN CONE' : user.name.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.card3DGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          // 3D Multi-layer Shadows
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Hiệu ứng dải sáng phản quang chéo (Holographic Sheen)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng đỉnh thẻ: Logo COne + Chip EMV 3D + Sóng NFC
                  Row(
                    children: [
                      // Chip EMV Vàng Kim 3D
                      Container(
                        width: 44,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.chipGoldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 22,
                                height: 16,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF6B4E00),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 1,
                                height: 26,
                                color: const Color(0xFF6B4E00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Icon sóng NFC không dây
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 26,
                      ),
                      const Spacer(),
                      // Nhãn dập nổi sinh viên COne
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.cyanAccent,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'STUDENT VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mã số sinh viên dập nổi to bản phong cách thẻ ngân hàng
                  Text(
                    user.code.isEmpty ? 'COne 2026 8888' : user.code.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(1.5, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Họ và tên + Nút Quét QR nổi 3D
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHỦ THẺ / CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.studentClass} • ${user.department}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.cyanAccent.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút 3D Tactile Quét QR
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onQrTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'QUÉT ĐIỂM DANH',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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


// -------------------------------------------------------------
// 3. KHỐI ĐIỂM RÈN LUYỆN 3D BENTO GAUGE
// -------------------------------------------------------------
class _Dashboard3DGrid extends StatelessWidget {
  const _Dashboard3DGrid({
    required this.data,
    required this.profileStatus,
    required this.isWide,
    required this.onDrlTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final _StudentDashboardData data;
  final String profileStatus;
  final bool isWide;
  final VoidCallback onDrlTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  String _getGradeLabel(double score) {
    if (score >= 90) return 'XUẤT SẮC';
    if (score >= 80) return 'TỐT';
    if (score >= 65) return 'KHÁ';
    if (score >= 50) return 'TRUNG BÌNH';
    if (score > 0) return 'CẦN CỐ GẮNG';
    return 'ĐANG TÍCH LŨY';
  }

  Color _getGradeColor(double score) {
    if (score >= 90) return const Color(0xFF8B5CF6);
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFF2563EB);
    if (score >= 50) return const Color(0xFFF59E0B);
    if (score > 0) return const Color(0xFFEF4444);
    return const Color(0xFF3B82F6);
  }

  IconData _getGradeIcon(double score) {
    if (score >= 90) return Icons.military_tech_rounded;
    if (score >= 80) return Icons.stars_rounded;
    if (score >= 65) return Icons.verified_rounded;
    if (score >= 50) return Icons.trending_up_rounded;
    return Icons.hourglass_top_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currentSemester = data.summary.semesterSummaries.isEmpty
        ? null
        : data.summary.semesterSummaries.first;
    final score = currentSemester?.totalPoints ?? data.summary.totalPoints;
    final activityCount = currentSemester?.activityCount ?? 0;
    final semesterName = currentSemester?.semesterName.isNotEmpty == true
        ? currentSemester!.semesterName
        : 'Học kỳ hiện tại';
    final gradeLabel = _getGradeLabel(score);
    final gradeColor = _getGradeColor(score);

    return Column(
      children: [
        // Thẻ Lớn: Điểm Rèn Luyện 3D Bento Gauge Redesigned
        GestureDetector(
          onTap: onDrlTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng tiêu đề: Tên kỳ + Badge Xếp loại
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          semesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: gradeColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getGradeIcon(score), size: 14, color: gradeColor),
                          const SizedBox(width: 4),
                          Text(
                            gradeLabel,
                            style: TextStyle(
                              color: gradeColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Thân thẻ: Vòng tròn điểm 3D bên trái + Các chỉ số bên phải
                Row(
                  children: [
                    // 3D Circular Progress Gauge
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: gradeColor.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: CircularProgressIndicator(
                              value: (score / 100).clamp(0.0, 1.0),
                              strokeWidth: 9,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                score.toStringAsFixed(score % 1 == 0 ? 0 : 1),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: gradeColor,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Cột chỉ số chi tiết lấp đầy phía bên phải
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hộp 1: Số hoạt động đã tham gia
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.event_available_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hoạt động kỳ này',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$activityCount hoạt động đã tham gia',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Hộp 2: Mục tiêu rèn luyện
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flag_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mục tiêu xếp loại',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        score >= 80
                                            ? 'Đã đạt chuẩn Tốt 🏅'
                                            : 'Cần thêm ${(80 - score).clamp(0, 100).toInt()}đ để đạt Tốt',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                // Footer thanh bấm vào xem chi tiết
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Bảng phân tích 5 tiêu chí rèn luyện',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// -------------------------------------------------------------
// 4. LƯỚI CHỨC NĂNG 3D
// -------------------------------------------------------------
class _QuickAction3DGrid extends StatelessWidget {
  const _QuickAction3DGrid({
    required this.isWide,
    required this.onActivities,
    required this.onRegisteredActivities,
    required this.onStats,
    required this.onDrl,
    required this.onEvidence,
    required this.onAppellations,
    required this.onQr,
    required this.onNotifications,
    required this.onChatbot,
    required this.onComplaints,
    required this.onPermissionRequests,
    required this.onDocuments,
    required this.onProfileStatus,
    required this.onCv,
    required this.onActivitySuggestions,
    required this.onSignatureRequests,
  });

  final bool isWide;
  final VoidCallback onActivities;
  final VoidCallback onRegisteredActivities;
  final VoidCallback onStats;
  final VoidCallback onDrl;
  final VoidCallback onEvidence;
  final VoidCallback onAppellations;
  final VoidCallback onQr;
  final VoidCallback onNotifications;
  final VoidCallback onChatbot;
  final VoidCallback onComplaints;
  final VoidCallback onPermissionRequests;
  final VoidCallback onDocuments;
  final VoidCallback onProfileStatus;
  final VoidCallback onCv;
  final VoidCallback onActivitySuggestions;
  final VoidCallback onSignatureRequests;

  void _showMoreServices(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'Dịch vụ & Tiện ích khác',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            _MoreServiceTile(
              icon: Icons.query_stats_outlined,
              title: 'Thống kê cá nhân',
              onTap: onStats,
            ),
            _MoreServiceTile(
              icon: Icons.event_note_outlined,
              title: 'Hoạt động đã đăng ký',
              onTap: onRegisteredActivities,
            ),
            _MoreServiceTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Danh hiệu',
              onTap: onAppellations,
            ),
            _MoreServiceTile(
              icon: Icons.report_problem_outlined,
              title: 'Khiếu nại',
              onTap: onComplaints,
            ),
            _MoreServiceTile(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Giấy xin phép',
              onTap: onPermissionRequests,
            ),
            _MoreServiceTile(
              icon: Icons.folder_copy_outlined,
              title: 'Tài liệu hồ sơ',
              onTap: onDocuments,
            ),
            _MoreServiceTile(
              icon: Icons.badge_outlined,
              title: 'CV sinh viên',
              onTap: onCv,
            ),
            _MoreServiceTile(
              icon: Icons.lightbulb_outline,
              title: 'Gợi ý hoạt động',
              onTap: onActivitySuggestions,
            ),
            _MoreServiceTile(
              icon: Icons.draw_outlined,
              title: 'Chữ ký số',
              onTap: onSignatureRequests,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isWide ? 1.6 : 1.35,
      children: [
        _FeatureCard3D(
          title: 'Hoạt động',
          icon: Icons.event_available_rounded,
          color: AppColors.primary,
          onTap: onActivities,
        ),
        _FeatureCard3D(
          title: 'Bảng điểm ĐRL',
          icon: Icons.bar_chart_rounded,
          color: AppColors.cyan,
          onTap: onDrl,
        ),
        _FeatureCard3D(
          title: 'Thống kê',
          icon: Icons.insights_rounded,
          color: const Color(0xFF6366F1),
          badge: 'MỚI',
          onTap: onStats,
        ),
        _FeatureCard3D(
          title: 'Minh chứng',
          icon: Icons.upload_file_rounded,
          color: AppColors.teal,
          onTap: onEvidence,
        ),
        _FeatureCard3D(
          title: 'Đã đăng ký',
          icon: Icons.event_note_rounded,
          color: const Color(0xFFE11D48),
          onTap: onRegisteredActivities,
        ),
        _FeatureCard3D(
          title: 'Khiếu nại',
          icon: Icons.report_problem_rounded,
          color: const Color(0xFFEA580C),
          onTap: onComplaints,
        ),
        _FeatureCard3D(
          title: 'Danh hiệu',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.purple,
          badge: 'TOP',
          onTap: onAppellations,
        ),
        _FeatureCard3D(
          title: 'Dịch vụ khác',
          icon: Icons.grid_view_rounded,
          color: AppColors.warning,
          onTap: () => _showMoreServices(context),
        ),
      ],
    );
  }
}

class _FeatureCard3D extends StatelessWidget {
  const _FeatureCard3D({
    required this.title,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              const BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.20),
                          color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SKELETON & FALLBACK
// -------------------------------------------------------------
class _DashboardFallback extends StatelessWidget {
  const _DashboardFallback({
    required this.message,
    required this.profileStatus,
    required this.onRetry,
  });

  final String message;
  final String profileStatus;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return COneCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard chưa tải được',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hồ sơ: $profileStatus • $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return const COneCard(
      child: SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
    );
  }
}

class _MoreServiceTile extends StatelessWidget {
  const _MoreServiceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

class _AnimatedAiSuggestionBanner extends StatefulWidget {
  const _AnimatedAiSuggestionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AnimatedAiSuggestionBanner> createState() =>
      _AnimatedAiSuggestionBannerState();
}

class _AnimatedAiSuggestionBannerState
    extends State<_AnimatedAiSuggestionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Hiệu ứng nhún nhảy nhẹ nhàng thu hút chú ý
    _bounceAnimation = Tween<double>(begin: 0.0, end: -4.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Hiệu ứng ánh sáng tỏa ra nhấp nháy
    _glowAnimation = Tween<double>(begin: 0.22, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFBEB),
                      Color(0xFFFEF3C7),
                      Color(0xFFFDE68A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFFF59E0B),
                      const Color(0xFFEA580C),
                      _glowAnimation.value,
                    )!,
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: _glowAnimation.value),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon 3D AI lấp lánh có hiệu ứng hào quang
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nội dung gợi ý
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEA580C),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        color: Colors.white, size: 11),
                                    SizedBox(width: 2),
                                    Text(
                                      'AI GỢI Ý',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Gợi ý rèn luyện',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Khám phá hoạt động phù hợp giúp tăng nhanh điểm ĐRL!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút bấm "Xem ngay" nổi bật
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
