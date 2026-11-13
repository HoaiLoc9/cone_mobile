import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

class AdminDrlAssessmentsScreen extends StatefulWidget {
  const AdminDrlAssessmentsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminDrlAssessmentsScreen> createState() =>
      _AdminDrlAssessmentsScreenState();
}

class _AdminDrlAssessmentsScreenState extends State<AdminDrlAssessmentsScreen> {
  late Future<List<AdminDrlAssessment>> _future = widget.service
      .drlAssessments();
  final Set<String> _approvingIds = {};

  void _reload() {
    setState(() => _future = widget.service.drlAssessments());
  }

  Future<void> _approve(AdminDrlAssessment item) async {
    setState(() => _approvingIds.add(item.id));
    try {
      await widget.service.approveDrl(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã duyệt phiếu DRL.')));
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _approvingIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Duyệt điểm rèn luyện',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<AdminDrlAssessment>>(
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
              message: 'Chưa có phiếu DRL trong phạm vi quản lý.',
              onRetry: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _DrlCard(
                  item: item,
                  isApproving: _approvingIds.contains(item.id),
                  onApprove: item.isApproved ? null : () => _approve(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DrlCard extends StatelessWidget {
  const _DrlCard({
    required this.item,
    required this.isApproving,
    required this.onApprove,
  });

  final AdminDrlAssessment item;
  final bool isApproving;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isApproved
        ? const Color(0xFF059669)
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.07),
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
          const SizedBox(height: 8),
          Text(
            item.semesterName,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(
                label: item.isApproved ? 'Đã duyệt' : 'Chờ duyệt',
                color: statusColor,
              ),
              if (item.updatedAt.isNotEmpty)
                _Chip(
                  label: 'Cập nhật ${item.updatedAt}',
                  color: AppColors.primary,
                ),
            ],
          ),
          if (!item.isApproved) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isApproving ? null : onApprove,
                icon: isApproving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Duyệt phiếu'),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        color: color.withValues(alpha: 0.10),
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
