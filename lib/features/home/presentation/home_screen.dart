import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/smooth_page_route.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late AuthSession _session;
  late final ValueNotifier<AuthSession> _sessionNotifier;
  late final DrlService _drlService;
  late final NotificationService _notificationService;
  late final StudentServicesService _studentServicesService;
  late Future<_StudentDashboardData> _dashboardFuture;
  int _currentNavIndex = 0;
  int _unreadCount = 0;

  Timer? _notificationSyncTimer;
  final Set<String> _notifiedNoticeIds = {};

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.session;
    _sessionNotifier = ValueNotifier<AuthSession>(_session);
    _drlService = DrlService(token: _session.token);
    _notificationService = NotificationService(token: _session.token);
    _studentServicesService = StudentServicesService(token: _session.token);
    _dashboardFuture = _loadDashboard();
    _startNotificationPolling();
    _syncPushToken();
  }

  Future<void> _syncPushToken() async {
    if (!kIsWeb) return;
    try {
      final status = LocalNotificationService.instance.checkWebPermissionStatus();
      if (status == 'granted') {
        final sub = await LocalNotificationService.instance.getPushSubscription();
        if (sub != null) {
          await _notificationService.registerPushSubscription(sub);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSyncTimer?.cancel();
    _sessionNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewNotifications();
    }
  }

  void _startNotificationPolling() {
    _notificationSyncTimer?.cancel();
    // 1. Kiểm tra ngay lập tức khi mở app
    _checkNewNotifications();
    // 2. Định kỳ mỗi 15 giây tự động đồng bộ để bắt thông báo Admin vừa đẩy
    _notificationSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkNewNotifications();
    });
  }

  Future<void> _checkNewNotifications() async {
    if (!mounted) return;
    try {
      final list = await _notificationService.fetchNotifications(unreadOnly: true);
      if (!mounted) return;

      if (_unreadCount != list.unreadCount) {
        setState(() => _unreadCount = list.unreadCount);
      }

      if (list.items.isEmpty) return;

      final lastNotifiedId = await AppStorage.instance.getString('cone_last_notified_id');

      // Nếu là lần đầu mở app, lưu id hiện tại để không bắn spam các thông báo cũ trước đó
      if (lastNotifiedId == null) {
        await AppStorage.instance.setString('cone_last_notified_id', list.items.first.id);
        for (final item in list.items) {
          _notifiedNoticeIds.add(item.id);
        }
        return;
      }

      // Quét các thông báo mới Admin vừa gửi (chưa từng được thông báo)
      for (final item in list.items) {
        if (!_notifiedNoticeIds.contains(item.id) && item.id != lastNotifiedId) {
          _notifiedNoticeIds.add(item.id);

          // Rung chuông và hiển thị thông báo đẩy lên màn hình điện thoại ngay lập tức!
          await LocalNotificationService.instance.showNotification(
            id: item.id.hashCode,
            title: item.title,
            body: item.message,
          );
        }
      }

      // Cập nhật id thông báo mới nhất
      await AppStorage.instance.setString('cone_last_notified_id', list.items.first.id);
    } catch (_) {}
  }

  Future<_StudentDashboardData> _loadDashboard() async {
    final results = await Future.wait<Object>([
      _drlService.fetchSummary(),
      _notificationService.fetchUnreadCount(),
    ]);
    final unread = results[1] as int;
    if (mounted) setState(() => _unreadCount = unread);
    return _StudentDashboardData(
      summary: results[0] as DrlSummary,
      unreadNotifications: unread,
    );
  }

  void _reloadDashboard() {
    setState(() => _dashboardFuture = _loadDashboard());
  }

  void _pushScreen(Widget screen) {
    _navigatorKeys[_currentNavIndex].currentState?.push(
      SmoothPageRoute(builder: (_) => screen),
    );
  }

  void _openRegisteredActivities() {
    _pushScreen(
      RegisteredActivitiesScreen(
        service: ActivityService(token: _session.token),
      ),
    );
  }

  void _openQrScan() {
    _pushScreen(
      QrScanScreen(
        service: QrScanService(token: _session.token),
        onComplete: () {
          if (mounted) {
            setState(() => _currentNavIndex = 0);
            _reloadDashboard();
          }
        },
      ),
    );
  }

  void _openDrl() {
    _pushScreen(DrlSummaryScreen(service: _drlService, session: _session));
  }

  void _openEvidence() {
    _pushScreen(
      MissingAttendanceScreen(
        service: ActivitySupportService(token: _session.token),
      ),
    );
  }

  void _openAppellations() {
    _pushScreen(
      AppellationListScreen(
        service: AppellationService(token: _session.token),
      ),
    );
  }

  void _openNotifications() {
    setState(() => _currentNavIndex = 3);
  }

  void _openChatbot() {
    _pushScreen(
      ChatbotScreen(service: ChatbotService(token: _session.token)),
    );
  }

  void _openComplaints() {
    _pushScreen(
      ComplaintsScreen(service: _studentServicesService),
    );
  }

  void _openPermissionRequests() {
    _pushScreen(
      PermissionRequestsScreen(service: _studentServicesService),
    );
  }

  void _openDocuments() {
    _pushScreen(
      DocumentsScreen(service: _studentServicesService),
    );
  }

  void _openProfileStatus() {
    _pushScreen(ProfileStatusScreen(service: _studentServicesService));
  }

  void _openCv() {
    _pushScreen(CvScreen(service: _studentServicesService));
  }

  void _openActivitySuggestions() {
    _pushScreen(
      ActivitySuggestionsScreen(service: _studentServicesService),
    );
  }

  void _openSignatureRequests() {
    _pushScreen(
      SignatureRequestsScreen(service: _studentServicesService),
    );
  }

  void _openProfile() {
    setState(() => _currentNavIndex = 4);
  }

  Widget _buildCircularHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.adaptiveCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.adaptiveTextPrimary),
                if (hasBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget Function() rootBuilder) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => ListenableBuilder(
            listenable: LocaleService.instance,
            builder: (_, _) => rootBuilder(),
          ),
        );
      },
    );
  }

  Widget _buildActivitiesScreen() {
    return ActivityListScreen(
      service: ActivityService(token: _session.token),
    );
  }

  Widget _buildStatsScreen() {
    return StudentStatsScreen(
      drlService: _drlService,
      activityService: ActivityService(token: _session.token),
      notificationService: _notificationService,
      session: _session,
    );
  }

  Widget _buildNotificationsScreen() {
    return NotificationListScreen(
      service: _notificationService,
    );
  }

  Widget _buildProfileScreen() {
    return ValueListenableBuilder<AuthSession>(
      valueListenable: _sessionNotifier,
      builder: (context, currentSession, _) {
        return ProfileScreen(
          service: ProfileService(token: currentSession.token),
          session: currentSession,
          onLogout: widget.onLogout,
          onProfileUpdated: (profileUser) {
            final updatedSession = AuthSession(
              token: _session.token,
              user: profileUser.toStudentUser(),
            );
            setState(() {
              _session = updatedSession;
            });
            _sessionNotifier.value = updatedSession;
            AuthService().saveSession(updatedSession).catchError((_) {});
          },
        );
      },
    );
  }

  Widget _buildDashboardScreen() {
    return ValueListenableBuilder<AuthSession>(
      valueListenable: _sessionNotifier,
      builder: (context, currentSession, _) {
        final user = currentSession.user;
        final hour = DateTime.now().hour;
        final greeting = hour < 11
            ? tr('Chào buổi sáng', 'Good morning')
            : (hour < 14
                ? tr('Chào buổi trưa', 'Good afternoon')
                : (hour < 18
                    ? tr('Chào buổi chiều', 'Good afternoon')
                    : tr('Chào buổi tối', 'Good evening')));

        return Stack(
          children: [
            AppShell(
              title: greeting,
              customTitle: Row(
            children: [
              GestureDetector(
                onTap: _openProfile,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.avatarUrl.isNotEmpty
                        ? Image.network(
                            user.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFDBEAFE),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFDBEAFE),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tr('COne • CĐ Kinh tế Đối ngoại', 'COne • COFER Student Portal'),
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
            ],
          ),
          actions: [
            _buildCircularHeaderButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Thông báo',
              hasBadge: _unreadCount > 0,
              onTap: _openNotifications,
            ),
            const SizedBox(width: 8),
            _buildCircularHeaderButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Làm mới',
              onTap: _reloadDashboard,
            ),
            const SizedBox(width: 14),
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
                          _Student3DCard(session: currentSession, onQrTap: _openQrScan),
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 16),
                          _AnimatedAiSuggestionBanner(
                            onTap: _openActivitySuggestions,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            tr('Tiện ích hệ thống', 'Quick Utilities'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _QuickAction3DGrid(
                            isWide: isWide,
                            onRegisteredActivities: _openRegisteredActivities,
                            onDrl: _openDrl,
                            onEvidence: _openEvidence,
                            onAppellations: _openAppellations,
                            onComplaints: _openComplaints,
                            onPermissionRequests: _openPermissionRequests,
                            onDocuments: _openDocuments,
                            onProfileStatus: _openProfileStatus,
                            onCv: _openCv,
                            onSignatureRequests: _openSignatureRequests,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
            ),
            DraggableAiRobotOverlay(
              onTap: _openChatbot,
              greetingText: tr('Hỏi AI nhé! ✨', 'Ask AI! ✨'),
            ),
          ],
        );
      },
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
          final currentNav = _navigatorKeys[_currentNavIndex].currentState;
          if (currentNav != null && currentNav.canPop()) {
            currentNav.pop();
            return;
          }
          if (_currentNavIndex != 0) {
            setState(() => _currentNavIndex = 0);
            return;
          }
        },
        child: LazyTabStack(
          currentIndex: _currentNavIndex,
          tabBuilders: [
            () => _buildTabNavigator(0, _buildDashboardScreen),
            () => _buildTabNavigator(1, _buildActivitiesScreen),
            () => _buildTabNavigator(2, _buildStatsScreen),
            () => _buildTabNavigator(3, _buildNotificationsScreen),
            () => _buildTabNavigator(4, _buildProfileScreen),
          ],
        ),
      ),
      bottomNavigationBar: _AppBottomNavBar(
        currentIndex: _currentNavIndex,
        unreadCount: _unreadCount,
        onTap: (index) {
          if (_currentNavIndex == index) {
            // Tapping the active tab pops back to root of this tab
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _currentNavIndex = index);
          }
        },
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
    final studentName = user.name.isEmpty ? 'NGUYỄN VĂN AN' : user.name.toUpperCase();
    final studentCode = user.code.isEmpty ? '22714651' : user.code.toUpperCase();
    final studentClass = user.studentClass.isEmpty ? 'DHTH18A' : user.studentClass;
    final department = user.department.isEmpty ? 'Khoa Công nghệ Thông tin' : user.department;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.40),
            blurRadius: 26,
            offset: const Offset(0, 14),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Quầng sáng phản quang
            Positioned(
              top: -50,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Ảnh thật khuôn viên trường Cao đẳng Kinh tế Đối ngoại (COFER)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 235,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Color(0x33000000),
                        Colors.black,
                      ],
                      stops: [0.0, 0.24, 0.82],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Opacity(
                    opacity: 0.92,
                    child: Image.asset(
                      'assets/images/campus_real.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.60, 0.0),
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),

            // Nội dung thông tin thẻ
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng đỉnh thẻ: Chip EMV + Sóng NFC + STUDENT VIP Crown
                  Row(
                    children: [
                      // Chip EMV Vàng Kim 3D
                      Container(
                        width: 44,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.chipGoldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
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
                      const SizedBox(width: 10),
                      // Sóng NFC
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 26,
                      ),
                      const Spacer(),
                      // Nhãn STUDENT VIP với vương miện
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 5),
                            Text(
                              'STUDENT VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Mã số sinh viên dập nổi lớn
                  Text(
                    studentCode,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(1.5, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Họ tên + Nút Quét điểm danh trắng
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
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
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
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$studentClass • $department',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút Quét điểm danh màu trắng
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onQrTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tr('QUÉT ĐIỂM DANH', 'SCAN QR'),
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11,
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
    if (score >= 90) return tr('XUẤT SẮC', 'EXCELLENT');
    if (score >= 80) return tr('TỐT', 'GOOD');
    if (score >= 65) return tr('KHÁ', 'FAIR');
    if (score >= 50) return tr('TRUNG BÌNH', 'AVERAGE');
    if (score > 0) return tr('CẦN CỐ GẮNG', 'NEEDS WORK');
    return tr('ĐANG TÍCH LŨY', 'IN PROGRESS');
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
              gradient: LinearGradient(
                colors: [AppColors.adaptiveCard, AppColors.cardSubtle],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.adaptiveBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: AppColors.isDark ? 0.20 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.adaptiveTextPrimary,
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
                        color: AppColors.adaptiveCard,
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
                              backgroundColor: AppColors.cardSubtle,
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
                              Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.adaptiveTextSecondary,
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
                              color: AppColors.cardSubtle,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.adaptiveBorder),
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
                                      Text(
                                        tr('Hoạt động kỳ này', 'This Semester'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.adaptiveTextSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        tr('$activityCount hoạt động đã tham gia', '$activityCount activities attended'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.adaptiveTextPrimary,
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
                              color: AppColors.cardSubtle,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.adaptiveBorder),
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
                                      Text(
                                        tr('Mục tiêu xếp loại', 'Target Rank'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.adaptiveTextSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        score >= 80
                                            ? tr('Đã đạt chuẩn Tốt 🏅', 'Good rank achieved 🏅')
                                            : tr(
                                                'Cần thêm ${(80 - score).clamp(0, 100).toInt()}đ để đạt Tốt',
                                                'Need ${(80 - score).clamp(0, 100).toInt()} more pts for Good',
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.adaptiveTextPrimary,
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
                Divider(height: 1, thickness: 0.8, color: AppColors.adaptiveBorder),
                const SizedBox(height: 12),
                // Footer thanh bấm vào xem chi tiết
                Row(
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
                          tr('Bảng phân tích 5 tiêu chí rèn luyện', '5 Conduct Criteria Breakdown'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          tr('Chi tiết', 'Details'),
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
    required this.onRegisteredActivities,
    required this.onDrl,
    required this.onEvidence,
    required this.onAppellations,
    required this.onComplaints,
    required this.onPermissionRequests,
    required this.onDocuments,
    required this.onProfileStatus,
    required this.onCv,
    required this.onSignatureRequests,
  });

  final bool isWide;
  final VoidCallback onRegisteredActivities;
  final VoidCallback onDrl;
  final VoidCallback onEvidence;
  final VoidCallback onAppellations;
  final VoidCallback onComplaints;
  final VoidCallback onPermissionRequests;
  final VoidCallback onDocuments;
  final VoidCallback onProfileStatus;
  final VoidCallback onCv;
  final VoidCallback onSignatureRequests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 nút chức năng quan trọng (không trùng Bottom Bar, đồng bộ tông xanh COne)
        GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.5 : 2.05,
          children: [
            _FeatureCard3D(
              title: tr('Bảng điểm ĐRL', 'Conduct Score'),
              subtitle: tr('Xem kết quả rèn luyện', 'View semester scores'),
              icon: Icons.bar_chart_rounded,
              color: AppColors.primary,
              onTap: onDrl,
            ),
            _FeatureCard3D(
              title: tr('Minh chứng', 'Evidence'),
              subtitle: tr('Tải lên & quản lý', 'Upload & track'),
              icon: Icons.upload_file_rounded,
              color: AppColors.primary,
              onTap: onEvidence,
            ),
            _FeatureCard3D(
              title: tr('Đã đăng ký', 'Registered'),
              subtitle: tr('Lịch hoạt động của bạn', 'Your activity schedule'),
              icon: Icons.event_note_rounded,
              color: AppColors.primary,
              onTap: onRegisteredActivities,
            ),
            _FeatureCard3D(
              title: tr('Danh hiệu', 'Awards'),
              subtitle: tr('Thành tích của bạn', 'Your achievements'),
              icon: Icons.workspace_premium_rounded,
              color: AppColors.primary,
              badge: 'TOP',
              onTap: onAppellations,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Thanh trượt ngang hình tròn kiểu Messenger (màu sắc đồng bộ)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Dịch vụ & Tiện ích', 'Services & Tools'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
            Text(
              tr('Trượt ngang →', 'Swipe →'),
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
          height: 106,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              _CircleServiceBubble(
                icon: Icons.warning_amber_rounded,
                label: tr('Khiếu nại', 'Complaints'),
                onTap: onComplaints,
              ),
              _CircleServiceBubble(
                icon: Icons.assignment_turned_in_rounded,
                label: tr('Giấy xin phép', 'Leave Form'),
                onTap: onPermissionRequests,
              ),
              _CircleServiceBubble(
                icon: Icons.draw_rounded,
                label: tr('Chữ ký số', 'E-Sign'),
                onTap: onSignatureRequests,
              ),
              _CircleServiceBubble(
                icon: Icons.verified_user_rounded,
                label: tr('Hồ sơ SV', 'Profile'),
                onTap: onProfileStatus,
              ),
              _CircleServiceBubble(
                icon: Icons.folder_copy_rounded,
                label: tr('Tài liệu', 'Docs'),
                onTap: onDocuments,
              ),
              _CircleServiceBubble(
                icon: Icons.badge_rounded,
                label: tr('CV sinh viên', 'Resume CV'),
                badge: 'PRO',
                onTap: onCv,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleServiceBubble extends StatelessWidget {
  const _CircleServiceBubble({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.45)
                            : const Color(0xFFBFDBFE),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                      size: 25,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -3,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.adaptiveBackground,
                            width: 1.8,
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
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

class _FeatureCard3D extends StatelessWidget {
  const _FeatureCard3D({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.adaptiveBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.20 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Hộp icon bo tròn màu phấn
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 9),
              // Nội dung Tiêu đề + Phụ đề
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.adaptiveTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard chưa tải được',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hồ sơ: $profileStatus • $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.adaptiveTextSecondary,
              size: 22,
            ),
          ),
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
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
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

    _bounceAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
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
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.isDark
                        ? const [Color(0xFF172554), Color(0xFF0F172A)]
                        : const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.isDark
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _glowAnimation.value * 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Hộp vuông xanh ánh sao đồng bộ
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nội dung
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1E3A8A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      tr('AI GỢI Ý', 'AI PICK'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  tr('Gợi ý rèn luyện', 'Smart Suggestions'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.isDark
                                        ? const Color(0xFFDBEAFE)
                                        : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('Khám phá hoạt động phù hợp với bạn.', 'Discover activities tailored for you.'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF1E40AF),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút đồng bộ: Xem ngay >
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr('Xem ngay', 'Explore'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
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

// -------------------------------------------------------------
// 5. THANH ĐIỀU HƯỚNG DƯỚI (BOTTOM NAVIGATION BAR)
// -------------------------------------------------------------
class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        border: Border(
          top: BorderSide(color: AppColors.adaptiveBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, tr('Trang chủ', 'Home')),
              _buildNavItem(1, Icons.calendar_month_outlined, tr('Hoạt động', 'Activities')),
              _buildNavItem(2, Icons.bar_chart_rounded, tr('Thống kê', 'Stats')),
              _buildNavItem(
                3,
                Icons.notifications_none_rounded,
                tr('Thông báo', 'Alerts'),
                hasBadge: unreadCount > 0,
              ),
              _buildNavItem(4, Icons.person_outline_rounded, tr('Tài khoản', 'Account')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool hasBadge = false,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.primary : AppColors.adaptiveTextSecondary;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 23),
                if (hasBadge)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 2.5,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
