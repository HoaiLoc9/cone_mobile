import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../shared/widgets/app_error_view.dart';
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
                                        Builder(
                                          builder: (_) {
                                            final isAttended = item.registrationStatusLabel.contains('điểm danh') ||
                                                item.registrationStatusLabel.contains('Hoàn thành');
                                            final isHalf = item.isEnded && !isAttended;
                                            final double pts = isHalf ? (item.points / 2) : item.points;
                                            final Color clr = isHalf ? const Color(0xFFD97706) : AppColors.primary;

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: clr.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    '+${pts.toStringAsFixed(pts % 1 == 0 ? 0 : 1)}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w900,
                                                      color: clr,
                                                    ),
                                                  ),
                                                  Text(
                                                    isHalf ? 'điểm (50%)' : 'điểm',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: clr,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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
          tr('Thống kê rèn luyện', 'Conduct Statistics'),
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
              return AppErrorView.fromError(
                snapshot.error,
                fallbackTitle: tr('Chưa tải được thống kê', 'Unable to load statistics'),
                onRetry: _reload,
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  // 1. Thẻ tổng quan điểm + 3 chỉ số nhanh (gọn, 1 khối duy nhất)
                  _buildCompactOverviewCard(
                    data: data,
                    score: score,
                    currentSemesterName: currentSemester?.semesterName,
                    onScoreTap: currentSemester != null
                        ? () => _openSemesterDetail(currentSemester.semesterId)
                        : _openDrlSummary,
                  ),
                  const SizedBox(height: 18),

                  // 2. Tiến độ điểm qua các học kỳ (gọn, rõ từng kỳ)
                  _buildSemesterProgressSection(data.summary.semesterSummaries),
                  const SizedBox(height: 14),

                  // 3. Thang xếp loại thu gọn 1 dòng
                  _buildCompactRankingStrip(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactOverviewCard({
    required _StatsData data,
    required double score,
    String? currentSemesterName,
    required VoidCallback onScoreTap,
  }) {
    final (rankLabel, rankColor) = _getRankInfo(score);
    final progress = (score / 100).clamp(0.0, 1.0);
    final scoreText = score.toStringAsFixed(score % 1 == 0 ? 0 : 1);
    final goalText = score >= 90
        ? 'Đạt mức Xuất sắc'
        : (score >= 80
            ? 'Cần thêm ${(90 - score).ceil()}đ đạt Xuất sắc'
            : 'Cần thêm ${(80 - score).ceil()}đ đạt Tốt');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        children: [
          // Phần điểm rèn luyện kỳ hiện tại
          InkWell(
            onTap: onScoreTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentSemesterName ?? 'Học kỳ hiện tại',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rankLabel,
                          style: TextStyle(
                            color: rankColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -1,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, bottom: 4),
                        child: Text(
                          '/ 100 điểm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            goalText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adaptiveTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.adaptiveCardSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: AppColors.adaptiveBorder),

          // Hàng 3 chỉ số gọn (Hoạt động | Học kỳ | Tin mới)
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildInlineMetric(
                    value: '${data.registeredCount}',
                    label: 'Hoạt động',
                    onTap: () => _showRegisteredActivitiesSheet(data.registeredActivities),
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: AppColors.adaptiveBorder),
                Expanded(
                  child: _buildInlineMetric(
                    value: '${data.summary.semesterSummaries.length}',
                    label: 'Học kỳ',
                    onTap: () => _showRecordedSemestersSheet(data),
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: AppColors.adaptiveBorder),
                Expanded(
                  child: _buildInlineMetric(
                    value: '${data.unreadNotifications}',
                    label: 'Tin chưa đọc',
                    onTap: _openNotifications,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMetric({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
          ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Các học kỳ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: _openDrlSummary,
                child: const Text(
                  'Bảng điểm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.adaptiveBorder),
          ),
          child: Column(
            children: List.generate(summaries.length, (index) {
              final item = summaries[index];
              final s = item.totalPoints;
              final p = (s / 100).clamp(0.0, 1.0);
              final (rank, color) = _getRankInfo(s);

              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(18) : Radius.zero,
                      bottom: index == summaries.length - 1 ? const Radius.circular(18) : Radius.zero,
                    ),
                    onTap: () => _openSemesterDetail(item.semesterId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.semesterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.adaptiveTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.activityCount} HĐ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${s.toStringAsFixed(s % 1 == 0 ? 0 : 1)}đ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.adaptiveTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rank,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 17,
                                color: AppColors.adaptiveTextSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: p,
                              minHeight: 4.5,
                              backgroundColor: AppColors.adaptiveCardSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < summaries.length - 1)
                    Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.adaptiveBorder),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRankingStrip() {
    Widget chip(String label, String range, Color color) {
      return Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Row(
        children: [
          chip('Xuất sắc', '90–100', const Color(0xFF10B981)),
          chip('Tốt', '80–89', AppColors.primary),
          chip('Khá', '65–79', const Color(0xFF0284C7)),
          chip('TB', '50–64', AppColors.adaptiveTextSecondary),
        ],
      ),
    );
  }

  (String, Color) _getRankInfo(double score) {
    if (score >= 90) return ('Xuất sắc', const Color(0xFF10B981));
    if (score >= 80) return ('Tốt', AppColors.primary);
    if (score >= 65) return ('Khá', const Color(0xFF0284C7));
    if (score >= 50) return ('Trung bình', const Color(0xFFD97706));
    return ('Yếu', AppColors.danger);
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
