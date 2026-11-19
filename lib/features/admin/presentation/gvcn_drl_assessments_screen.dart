import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';
import 'gvcn_drl_detail_screen.dart';

class GvcnDrlAssessmentsScreen extends StatefulWidget {
  const GvcnDrlAssessmentsScreen({
    super.key,
    required this.service,
    this.initialStatus = '',
  });

  final AdminService service;
  final String initialStatus;

  @override
  State<GvcnDrlAssessmentsScreen> createState() =>
      _GvcnDrlAssessmentsScreenState();
}

class _GvcnDrlAssessmentsScreenState extends State<GvcnDrlAssessmentsScreen> {
  late String _status = widget.initialStatus;
  late Future<List<AdminDrlAssessment>> _future = widget.service
      .gvcnDrlAssessments(status: _status);

  void _reload() {
    setState(() {
      _future = widget.service.gvcnDrlAssessments(status: _status);
    });
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
      _future = widget.service.gvcnDrlAssessments(status: _status);
    });
  }

  Future<void> _openDetail(AdminDrlAssessment item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GvcnDrlDetailScreen(service: widget.service, assessmentId: item.id),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Phiếu ĐRL theo lớp',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Tất cả',
                  selected: _status == '',
                  onTap: () => _setStatus(''),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Chưa duyệt',
                  selected: _status == 'pending',
                  onTap: () => _setStatus('pending'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Đã duyệt',
                  selected: _status == 'approved',
                  onTap: () => _setStatus('approved'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminDrlAssessment>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SingleChildScrollView(
                    child: ShimmerListLoading(itemCount: 5),
                  );
                }
                if (snapshot.hasError) {
                  return _StateMessage(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return _StateMessage(
                    message: 'Chưa có phiếu ĐRL phù hợp bộ lọc.',
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _DrlCard(
                        item: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.adaptiveBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.adaptiveTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _DrlCard extends StatelessWidget {
  const _DrlCard({required this.item, required this.onTap});

  final AdminDrlAssessment item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isApproved
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);

    return Material(
      color: AppColors.adaptiveCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.adaptiveBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.studentName.isEmpty ? item.studentCode : item.studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: AppColors.adaptiveTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.studentCode} • ${item.semesterName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.isApproved ? 'Đã duyệt' : 'Chưa duyệt',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ScorePill(label: 'SV tự chấm', value: _score(item.studentTotal)),
                  const SizedBox(width: 8),
                  _ScorePill(label: 'GVCN', value: _score(item.classTotal)),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.adaptiveTextSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _score(double? value) =>
      value == null ? '-' : value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCardSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.adaptiveTextPrimary,
        ),
      ),
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
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.adaptiveTextSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
