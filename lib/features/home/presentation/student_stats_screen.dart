import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../activities/data/activity_service.dart';
import '../../drl/data/drl_models.dart';
import '../../drl/data/drl_service.dart';
import '../../notifications/data/notification_service.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({
    super.key,
    required this.drlService,
    required this.activityService,
    required this.notificationService,
  });

  final DrlService drlService;
  final ActivityService activityService;
  final NotificationService notificationService;

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
    return _StatsData(
      summary: results[0] as DrlSummary,
      registeredCount: (results[1] as List).length,
      unreadNotifications: results[2] as int,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thống kê rèn luyện',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18),
        ),
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_StatsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                  _buildHeroRadialScoreCard(score: score, currentSemesterName: currentSemester?.semesterName),
                  const SizedBox(height: 20),

                  // 2. Lưới 4 chỉ số thống kê KPI
                  _buildKpiGrid(data: data, score: score),
                  const SizedBox(height: 24),

                  // 3. Tiến độ điểm qua các học kỳ
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

  Widget _buildHeroRadialScoreCard({required double score, String? currentSemesterName}) {
    final (rankLabel, rankColor) = _getRankInfo(score);
    final progress = (score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
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
                          style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
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
                      child: const Text(
                        'Điểm tính theo thang 100',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiTile(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Học kỳ',
            value: '${data.summary.semesterSummaries.length}',
            unit: 'đã ghi nhận',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiTile(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Tin mới',
            value: '${data.unreadNotifications}',
            unit: 'chưa đọc',
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
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
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
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lịch sử rèn luyện qua các học kỳ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.semesterName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Row(
                          children: [
                            Text(
                              '${s.toStringAsFixed(s % 1 == 0 ? 0 : 1)}đ',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
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
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildRankRow('Xuất sắc', '90 - 100 điểm', const Color(0xFF10B981)),
          Divider(height: 14, color: AppColors.border),
          _buildRankRow('Tốt', '80 - 89 điểm', const Color(0xFF2563EB)),
          Divider(height: 14, color: AppColors.border),
          _buildRankRow('Khá', '65 - 79 điểm', const Color(0xFFF59E0B)),
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
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Text(rank, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
          ],
        ),
        Text(range, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                    ? 'Bạn đang giữ phong độ rất tốt! Hãy tiếp tục tham gia các hoạt động nghiên cứu khoa học hoặc chiến dịch tình nguyện để duy trì học bổng khuyến khích tài năng.'
                    : 'Hãy tham gia thêm ít nhất 2 hoạt động phong trào hoặc hoạt động kỹ năng trong tháng này để cải thiện bậc xếp loại rèn luyện lên mức Tốt nhé!',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.4),
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
    if (score >= 65) return ('KHÁ 👍', const Color(0xFFFBBF24));
    if (score >= 50) return ('TRUNG BÌNH', const Color(0xFFF97316));
    return ('YẾU', const Color(0xFFEF4444));
  }
}

class _StatsData {
  const _StatsData({
    required this.summary,
    required this.registeredCount,
    required this.unreadNotifications,
  });

  final DrlSummary summary;
  final int registeredCount;
  final int unreadNotifications;
}
