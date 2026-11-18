import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../activities/data/activity_model.dart';
import '../../activities/data/activity_service.dart';
import '../../activities/presentation/activity_detail_screen.dart';
import '../../activities/presentation/registered_activities_screen.dart';
import '../../auth/data/auth_service.dart';
import '../../drl/data/drl_models.dart';
import '../../drl/data/drl_service.dart';
import '../../drl/presentation/drl_detail_screen.dart';
import '../../drl/presentation/drl_summary_screen.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/presentation/notification_list_screen.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({
    super.key,
    required this.drlService,
    required this.activityService,
    required this.notificationService,
    this.session,
  });

  final DrlService drlService;
  final ActivityService activityService;
  final NotificationService notificationService;
  final AuthSession? session;

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  late Future<_StatsData> _future = _load();

  Future<_StatsData> _load() async {
    final results = await Future.wait<Object>([
      widget.drlService.fetchSummary(),
      widget.activityService.fetchRegisteredActivities(),
      widget.notificationService.fetchUnreadCount(),
    ]);
    final registeredList = (results[1] as List).cast<ActivityItem>();
    return _StatsData(
      summary: results[0] as DrlSummary,
      registeredActivities: registeredList,
      unreadNotifications: results[2] as int,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _openSemesterDetail(String semesterId) async {
    if (semesterId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrlDetailScreen(
          service: widget.drlService,
          semesterId: semesterId,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openDrlSummary() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrlSummaryScreen(
          service: widget.drlService,
          session: widget.session,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationListScreen(
          service: widget.notificationService,
        ),
      ),
    );
    if (mounted) _reload();
  }

  void _showRegisteredActivitiesSheet(List<ActivityItem> activities) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.adaptiveBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết hoạt động đã đăng ký (${activities.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.adaptiveTextPrimary,
                                ),
                              ),
                              Text(
                                'Nhấn vào từng hoạt động để xem chi tiết hoặc hủy đăng ký',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          icon: Icon(Icons.close_rounded, color: AppColors.adaptiveTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.adaptiveBorder),
                  Expanded(
                    child: activities.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 46,
                                    color: AppColors.adaptiveTextSecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Chưa có hoạt động đã đăng ký',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.adaptiveTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hãy khám phá và đăng ký các hoạt động phong trào để tích lũy điểm rèn luyện.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.adaptiveTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: activities.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = activities[index];
                              final statusText = item.registrationStatusLabel.isNotEmpty
                                  ? item.registrationStatusLabel
                                  : (item.statusLabel.isNotEmpty ? item.statusLabel : 'Đã đăng ký');
                              return Material(
                                color: AppColors.adaptiveCard,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () async {
                                    Navigator.of(sheetCtx).pop();
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ActivityDetailScreen(
                                          service: widget.activityService,
                                          activityId: item.id,
                                        ),
                                      ),
                                    );
                                    if (mounted) _reload();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.adaptiveBorder),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '+${item.points.toStringAsFixed(item.points % 1 == 0 ? 0 : 1)}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const Text(
                                                'điểm',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (item.semester.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        item.semester,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.adaptiveTextSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.adaptiveTextPrimary,
                                                ),
                                              ),
                                              if (item.location.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.place_outlined,
                                                      size: 13,
                                                      color: AppColors.adaptiveTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        item.location,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.adaptiveTextSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.adaptiveTextSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveCard,
                      border: Border(top: BorderSide(color: AppColors.adaptiveBorder)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisteredActivitiesScreen(
                                service: widget.activityService,
                              ),
                            ),
                          );
                          if (mounted) _reload();
                        },
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text(
                          'Quản lý toàn bộ hoạt động đã đăng ký',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordedSemestersSheet(_StatsData data) {
    final summaries = data.summary.semesterSummaries;
    final totalRecordedActivities = summaries.fold<int>(
      0,
      (sum, item) => sum + item.activityCount,
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.adaptiveBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết học kỳ đã ghi nhận (${summaries.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.adaptiveTextPrimary,
                                ),
                              ),
                              Text(
                                'Tổng cộng $totalRecordedActivities hoạt động đã ghi nhận điểm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          icon: Icon(Icons.close_rounded, color: AppColors.adaptiveTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.adaptiveBorder),
                  Expanded(
                    child: summaries.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                'Chưa có học kỳ nào được ghi nhận điểm rèn luyện.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: summaries.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final item = summaries[index];
                              final score = item.totalPoints;
                              final (rank, color) = _getRankInfo(score);

                              return Material(
                                color: AppColors.adaptiveCard,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.of(sheetCtx).pop();
                                    _openSemesterDetail(item.semesterId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.adaptiveBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.semesterName,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.adaptiveTextPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                rank,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.adaptiveCardSubtle,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Điểm ghi nhận',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.adaptiveTextSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)} / 100 điểm',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w900,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.adaptiveCardSubtle,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Hoạt động đã ghi nhận',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.adaptiveTextSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${item.activityCount} hoạt động',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w900,
                                                        color: AppColors.adaptiveTextPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'Xem bảng điểm chi tiết 5 tiêu chí',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveCard,
                      border: Border(top: BorderSide(color: AppColors.adaptiveBorder)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          _openDrlSummary();
                        },
                        icon: const Icon(Icons.bar_chart_rounded, size: 18),
                        label: const Text(
                          'Mở Bảng điểm Rèn luyện toàn khóa',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Thống kê rèn luyện',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_StatsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SingleChildScrollView(
                child: ShimmerListLoading(itemCount: 4),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa tải được thống kê',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final currentSemester = data.summary.semesterSummaries.isNotEmpty
                ? data.summary.semesterSummaries.first
                : null;
            final score = currentSemester?.totalPoints ?? data.summary.totalPoints;

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                children: [
                  // 1. Thẻ Hero Điểm Rèn Luyện & Vòng Tròn Radial Gauge
                  _buildHeroRadialScoreCard(
                    score: score,
                    currentSemesterName: currentSemester?.semesterName,
                    onTap: currentSemester != null
                        ? () => _openSemesterDetail(currentSemester.semesterId)
                        : _openDrlSummary,
                  ),
                  const SizedBox(height: 20),

                  // 2. Lưới chỉ số thống kê KPI (Ấn vào xem chi tiết đã đăng ký / đã ghi nhận)
                  _buildKpiGrid(data: data, score: score),
                  const SizedBox(height: 24),

                  // 3. Tiến độ điểm qua các học kỳ (Ấn vào từng kỳ để xem chi tiết)
                  _buildSemesterProgressSection(data.summary.semesterSummaries),
                  const SizedBox(height: 24),

                  // 4. Thang điểm & Tiêu chuẩn xếp loại
                  _buildRankingStandardCard(),
                  const SizedBox(height: 20),

                  // 5. Khuyến nghị thông minh từ hệ thống
                  _buildSmartRecommendationCard(score: score),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroRadialScoreCard({
    required double score,
    String? currentSemesterName,
    required VoidCallback onTap,
  }) {
    final (rankLabel, rankColor) = _getRankInfo(score);
    final progress = (score / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ĐIỂM RÈN LUYỆN KỲ NÀY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentSemesterName ?? 'Học kỳ hiện tại',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    rankLabel,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vòng tròn điểm số Radial Gauge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(score % 1 == 0 ? 0 : 1),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '/100 điểm',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mục tiêu học bổng:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score >= 90
                            ? 'Đã đạt chuẩn Xuất sắc! 🏆'
                            : (score >= 80
                                ? 'Cần thêm ${(90 - score).toInt()}đ để đạt Xuất sắc ⭐'
                                : 'Cần thêm ${(80 - score).toInt()}đ để đạt Tốt 🎯'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ấn xem chi tiết điểm',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid({required _StatsData data, required double score}) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiTile(
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Hoạt động',
            value: '${data.registeredCount}',
            unit: 'đã đăng ký',
            onTap: () => _showRegisteredActivitiesSheet(data.registeredActivities),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiTile(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF0284C7),
            title: 'Học kỳ',
            value: '${data.summary.semesterSummaries.length}',
            unit: 'đã ghi nhận',
            onTap: () => _showRecordedSemestersSheet(data),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiTile(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF1D4ED8),
            title: 'Tin mới',
            value: '${data.unreadNotifications}',
            unit: 'chưa đọc',
            onTap: _openNotifications,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 13,
                    color: iconColor.withValues(alpha: 0.75),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adaptiveTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Xem chi tiết',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 14, color: iconColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterProgressSection(List<DrlSemesterSummary> summaries) {
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lịch sử rèn luyện qua các học kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _openDrlSummary,
              child: const Text(
                'Tất cả',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: summaries.map((item) {
              final s = item.totalPoints;
              final p = (s / 100).clamp(0.0, 1.0);
              final (rank, color) = _getRankInfo(s);

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openSemesterDetail(item.semesterId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.semesterName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Đã ghi nhận ${item.activityCount} hoạt động • Ấn để xem chi tiết',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.adaptiveTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${s.toStringAsFixed(s % 1 == 0 ? 0 : 1)}đ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rank,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.adaptiveTextSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 8,
                          backgroundColor: AppColors.cardSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingStandardCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thang điểm xếp loại chuẩn COFER',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRankRow('Xuất sắc', '90 - 100 điểm', const Color(0xFF10B981)),
          Divider(height: 14, color: AppColors.border),
          _buildRankRow('Tốt', '80 - 89 điểm', const Color(0xFF2563EB)),
          Divider(height: 14, color: AppColors.border),
          _buildRankRow('Khá', '65 - 79 điểm', const Color(0xFF0284C7)),
          Divider(height: 14, color: AppColors.border),
          _buildRankRow('Trung bình', '50 - 64 điểm', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildRankRow(String rank, String range, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              rank,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
          ],
        ),
        Text(
          range,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
        ),
      ],
    );
  }

  Widget _buildSmartRecommendationCard({required double score}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFF2563EB), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gợi ý từ Cố vấn rèn luyện AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? 'Bạn đang giữ phong độ rất tốt! Hãy tiếp tục tham gia các hoạt động nghiên cứu khoa học hoặc chiến dịch tình nguyện để duy trì học bổng khuyến khích tài năng.'
                      : 'Hãy tham gia thêm ít nhất 2 hoạt động phong trào hoặc hoạt động kỹ năng trong tháng này để cải thiện bậc xếp loại rèn luyện lên mức Tốt nhé!',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _getRankInfo(double score) {
    if (score >= 90) return ('XUẤT SẮC 🏅', const Color(0xFF10B981));
    if (score >= 80) return ('TỐT ⭐', const Color(0xFF38BDF8));
    if (score >= 65) return ('KHÁ 👍', const Color(0xFF60A5FA));
    if (score >= 50) return ('TRUNG BÌNH', const Color(0xFFF59E0B));
    return ('YẾU', const Color(0xFFEF4444));
  }
}

class _StatsData {
  const _StatsData({
    required this.summary,
    required this.registeredActivities,
    required this.unreadNotifications,
  });

  final DrlSummary summary;
  final List<ActivityItem> registeredActivities;
  final int unreadNotifications;

  int get registeredCount => registeredActivities.length;
}
