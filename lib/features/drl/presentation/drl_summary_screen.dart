import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/achievement_story_modal.dart';
import '../../auth/data/auth_service.dart';
import '../data/drl_models.dart';
import '../data/drl_service.dart';
import 'drl_detail_screen.dart';
import 'drl_score_format.dart';
import 'drl_self_assessment_screen.dart';

class DrlSummaryScreen extends StatefulWidget {
  const DrlSummaryScreen({super.key, required this.service, this.session});

  final DrlService service;
  final AuthSession? session;

  @override
  State<DrlSummaryScreen> createState() => _DrlSummaryScreenState();
}

class _DrlSummaryScreenState extends State<DrlSummaryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DrlSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await widget.service.fetchSummary();
      setState(() => _summary = summary);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được điểm rèn luyện.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDetail(String semesterId) async {
    if (semesterId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrlDetailScreen(service: widget.service, semesterId: semesterId),
      ),
    );
    _load();
  }

  Future<void> _openSelfAssessment(String semesterId) async {
    if (semesterId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrlSelfAssessmentScreen(service: widget.service, semesterId: semesterId),
      ),
    );
    _load();
  }

  void _openShareStory(DrlSummary summary) {
    final user = widget.session?.user;
    final latestSemester = summary.semesterSummaries.isNotEmpty
        ? summary.semesterSummaries.first.semesterName
        : (summary.semesters.isNotEmpty ? summary.semesters.first.name : '');
    final (rankLabel, _) = _getRankBadge(summary.totalPoints);

    AchievementStoryModal.show(
      context,
      studentName: user?.name.isNotEmpty == true ? user!.name : 'Sinh viên COne',
      studentCode: user?.code.isNotEmpty == true ? user!.code : 'SV',
      studentClass: user?.studentClass.isNotEmpty == true ? user!.studentClass : 'KHTN',
      totalScore: summary.totalPoints,
      rankLabel: rankLabel,
      semesterName: latestSemester,
      activityCount: summary.semesterSummaries.fold<int>(0, (sum, item) => sum + item.activityCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Bảng điểm Rèn luyện',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.adaptiveTextPrimary, fontSize: 18),
        ),
        actions: [
          if (summary != null)
            IconButton(
              onPressed: () => _openShareStory(summary),
              icon: const Icon(Icons.share_rounded, color: AppColors.primary),
              tooltip: 'Chia sẻ Story thành tích',
            ),
          IconButton(
            onPressed: _load,
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
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildMessage(message: _errorMessage!, isError: true)
                  : summary == null
                      ? _buildMessage(message: 'Chưa có dữ liệu điểm rèn luyện.', isError: false)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          children: [
                            // 1. Thẻ Hero Điểm Tổng Kết
                            _buildHeroTotalCard(summary: summary),
                            const SizedBox(height: 24),

                            // 2. Tiêu đề danh sách theo học kỳ
                            Row(
                              children: [
                                const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Bảng điểm theo học kỳ',
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 3. Danh sách thẻ từng học kỳ
                            if (summary.semesterSummaries.isNotEmpty)
                              ...summary.semesterSummaries.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildSemesterCard(
                                    item: item,
                                    onTap: () => _openDetail(item.semesterId),
                                    onSelfAssess: () => _openSelfAssessment(item.semesterId),
                                  ),
                                ),
                              )
                            else
                              ...summary.semesters.map(
                                (semester) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildEmptySemesterCard(
                                    semester: semester,
                                    onTap: () => _openDetail(semester.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildHeroTotalCard({required DrlSummary summary}) {
    final score = summary.totalPoints;
    final (rankLabel, rankColor) = _getRankBadge(score);

    return Container(
      width: double.infinity,
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
            blurRadius: 22,
            offset: const Offset(0, 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.cyanAccent, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'TỔNG KẾT RÈN LUYỆN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  rankLabel,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatScore(score),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/100 điểm',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống quản lý điểm rèn luyện Trường Cao đẳng Kinh tế Đối ngoại',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _openShareStory(summary),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Chia sẻ Story thành tích ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard({
    required DrlSemesterSummary item,
    required VoidCallback onTap,
    required VoidCallback onSelfAssess,
  }) {
    final score = item.totalPoints;
    final (rankLabel, rankColor) = _getRankBadge(score);
    final progress = (score / 100).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                blurRadius: 10,
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
                  Expanded(
                    child: Text(
                      item.semesterName,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rankLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rankColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hộp điểm số
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        score.toStringAsFixed(score % 1 == 0 ? 0 : 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.activityCount} hoạt động đã ghi nhận điểm',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onSelfAssess,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Tự đánh giá DRL',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySemesterCard({
    required DrlSemester semester,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chưa có dữ liệu rèn luyện',
                      style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.adaptiveTextSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({required String message, required bool isError}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: isError ? const Color(0xFFEF4444) : AppColors.primary,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _getRankBadge(double score) {
    if (score >= 90) return ('XUẤT SẮC 🏅', const Color(0xFF10B981));
    if (score >= 80) return ('TỐT ⭐', const Color(0xFF38BDF8));
    if (score >= 65) return ('KHÁ', const Color(0xFFFBBF24));
    if (score >= 50) return ('TRUNG BÌNH', const Color(0xFFF97316));
    return ('YẾU', const Color(0xFFEF4444));
  }
}
