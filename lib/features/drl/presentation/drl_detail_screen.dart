import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/student_user.dart';
import '../data/drl_models.dart';
import '../data/drl_pdf_service.dart';
import '../data/drl_service.dart';
import 'drl_score_format.dart';
import 'drl_self_assessment_screen.dart';

class DrlDetailScreen extends StatefulWidget {
  const DrlDetailScreen({
    super.key,
    required this.service,
    required this.semesterId,
  });

  final DrlService service;
  final String semesterId;

  @override
  State<DrlDetailScreen> createState() => _DrlDetailScreenState();
}

class _DrlDetailScreenState extends State<DrlDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DrlDetail? _detail;

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
      final detail = await widget.service.fetchDetail(widget.semesterId);
      setState(() => _detail = detail);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được chi tiết điểm rèn luyện.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      final session = await AuthService().getSavedSession();
      final student = session?.user ??
          const StudentUser(
            id: '',
            code: 'SINH VIEN',
            name: 'Sinh viên',
            email: '',
            phone: '',
            studentClass: 'CĐ Kinh tế Đối ngoại',
            department: 'Khoa CNTT & QTKD',
          );

      await DrlPdfService.printOrShare(detail: detail, student: student);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xuất file PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          title: Text(
            detail?.semester.name ?? 'Chi tiết DRL',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (detail != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                tooltip: 'Xuất phiếu ĐRL (PDF)',
                onPressed: _exportPdf,
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hoạt động'),
              Tab(text: 'Tiêu chí'),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _Message(message: _errorMessage!, isError: true)
                  : detail == null
                      ? const _Message(message: 'Chưa có dữ liệu chi tiết.', isError: false)
                      : TabBarView(
                          children: [
                            _ActivityTab(detail: detail),
                            _CriteriaTab(
                              detail: detail,
                              service: widget.service,
                              semesterId: widget.semesterId,
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.detail});

  final DrlDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _HeaderCard(
          title: 'Điểm từ hoạt động',
          score: detail.activityScore.totalPoints,
          subtitle: '${detail.activityScore.rows.length} hoạt động trong học kỳ',
          icon: Icons.event_available_rounded,
        ),
        const SizedBox(height: 18),
        if (detail.activityScore.rows.isEmpty)
          const _EmptyCard(message: 'Chưa có hoạt động/điểm danh trong học kỳ này.')
        else
          ...detail.activityScore.rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ActivityScoreCard(row: row),
            ),
          ),
      ],
    );
  }
}

class _CriteriaTab extends StatelessWidget {
  const _CriteriaTab({
    required this.detail,
    required this.service,
    required this.semesterId,
  });

  final DrlDetail detail;
  final DrlService service;
  final String semesterId;

  @override
  Widget build(BuildContext context) {
    final criteria = detail.criteriaScore;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _HeaderCard(
          title: 'Điểm theo tiêu chí',
          score: criteria.studentTotal,
          subtitle: criteria.studentClassification.isEmpty
              ? 'Phiếu tự đánh giá DRL'
              : 'Xếp loại: ${criteria.studentClassification}',
          icon: Icons.fact_check_rounded,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DrlSelfAssessmentScreen(
                    service: service,
                    semesterId: semesterId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Nhập tự đánh giá / minh chứng'),
          ),
        ),
        const SizedBox(height: 14),
        _ComparisonCard(criteria: criteria),
        const SizedBox(height: 18),
        if (criteria.sections.isEmpty)
          const _EmptyCard(message: 'Chưa có cấu hình tiêu chí DRL.')
        else
          ...criteria.sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CriteriaSectionCard(section: section),
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.score,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final double score;
  final String subtitle;
  final IconData icon;

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
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatScore(score),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityScoreCard extends StatelessWidget {
  const _ActivityScoreCard({required this.row});

  final DrlActivityRow row;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.activityName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PointBadge(value: row.netPoints),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${formatDateTime(row.timeStart)} → ${formatDateTime(row.timeStop)}',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _MiniBadge(label: '+${formatScore(row.pointsPlus)}', color: const Color(0xFF059669)),
              _MiniBadge(label: '-${formatScore(row.pointsMinus)}', color: AppColors.danger),
            ],
          ),
          if (row.attendanceNote.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              row.attendanceNote,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.criteria});

  final DrlCriteriaScore criteria;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _ScoreLine(label: 'Sinh viên', value: criteria.studentTotal, note: criteria.studentClassification),
          _ScoreLine(label: 'Lớp', value: criteria.classTotal, note: criteria.classClassification),
          _ScoreLine(label: 'Cố vấn', value: criteria.advisorTotal, note: criteria.advisorClassification),
          if (criteria.activityHint != null)
            _ScoreLine(label: 'Gợi ý hoạt động', value: criteria.activityHint!, note: 'Từ điểm danh'),
        ],
      ),
    );
  }
}

class _CriteriaSectionCard extends StatelessWidget {
  const _CriteriaSectionCard({required this.section});

  final DrlCriteriaSection section;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Text(
          'Mục ${section.section}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          'SV ${formatScore(section.capped)} • Lớp ${formatScore(section.classCapped)} • CV ${formatScore(section.advisorCapped)}',
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
        ),
        children: section.criteria.map((criterion) => _CriterionTile(criterion: criterion)).toList(),
      ),
    );
  }
}

class _CriterionTile extends StatelessWidget {
  const _CriterionTile({required this.criterion});

  final DrlCriterion criterion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            criterion.label.isEmpty ? criterion.key : criterion.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (criterion.note.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              criterion.note,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: 'SV: ${_scoreOrDash(criterion.effectiveScore)}', color: AppColors.primary),
              _MiniBadge(label: 'Lớp: ${_scoreOrDash(criterion.classScore)}', color: const Color(0xFF7C3AED)),
              _MiniBadge(label: 'CV: ${_scoreOrDash(criterion.advisorScore)}', color: const Color(0xFF059669)),
              _MiniBadge(label: 'Max: ${formatScore(criterion.maxDisplay)}', color: AppColors.textSecondary),
              if (criterion.requiresEvidence)
                _MiniBadge(
                  label: criterion.hasEvidence ? 'Có minh chứng' : 'Cần minh chứng',
                  color: criterion.hasEvidence ? const Color(0xFF059669) : AppColors.danger,
                ),
            ],
          ),
          if ((criterion.sourceNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              criterion.sourceNote!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _scoreOrDash(double? value) => value == null ? '-' : formatScore(value);
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.label, required this.value, required this.note});

  final String label;
  final double value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            formatScore(value),
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              note,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  const _PointBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? const Color(0xFF059669) : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${positive ? '+' : ''}${formatScore(value)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
