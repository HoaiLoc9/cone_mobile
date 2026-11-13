import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
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
      appBar: AppBar(
        title: const Text(
          'Phiếu DRL theo lớp',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '', label: Text('Tất cả')),
                ButtonSegment(value: 'pending', label: Text('Chưa duyệt')),
                ButtonSegment(value: 'approved', label: Text('Đã duyệt')),
              ],
              selected: {_status},
              onSelectionChanged: (value) => _setStatus(value.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminDrlAssessment>>(
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
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return _StateMessage(
                    message: 'Chưa có phiếu DRL phù hợp bộ lọc.',
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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

class _DrlCard extends StatelessWidget {
  const _DrlCard({required this.item, required this.onTap});

  final AdminDrlAssessment item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isApproved
        ? const Color(0xFF059669)
        : const Color(0xFFF59E0B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.studentCode} • ${item.studentName}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              item.semesterName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: item.isApproved ? 'Đã duyệt' : 'Chưa duyệt',
                  color: statusColor,
                ),
                _Chip(
                  label: 'SV: ${_score(item.studentTotal)}',
                  color: AppColors.primary,
                ),
                _Chip(
                  label: 'GVCN: ${_score(item.classTotal)}',
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _score(double? value) =>
      value == null ? '-' : value.toStringAsFixed(1);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Tải lại')),
          ],
        ),
      ),
    );
  }
}
