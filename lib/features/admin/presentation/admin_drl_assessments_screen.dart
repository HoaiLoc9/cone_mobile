import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/shimmer_loading.dart';
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
  String _filter = 'all'; // all, pending, approved

  void _reload() {
    setState(() => _future = widget.service.drlAssessments());
  }

  Future<void> _approve(AdminDrlAssessment item) async {
    setState(() => _approvingIds.add(item.id));
    try {
      await widget.service.approveDrl(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt phiếu điểm rèn luyện.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _approvingIds.remove(item.id));
      }
    }
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
          'Duyệt điểm rèn luyện',
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
      body: FutureBuilder<List<AdminDrlAssessment>>(
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
          final allItems = snapshot.data ?? const [];
          final pendingCount = allItems.where((e) => !e.isApproved).length;
          final approvedCount = allItems.where((e) => e.isApproved).length;
          final items = switch (_filter) {
            'pending' => allItems.where((e) => !e.isApproved).toList(),
            'approved' => allItems.where((e) => e.isApproved).toList(),
            _ => allItems,
          };

          return Column(
            children: [
              // Bộ lọc nhanh
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _FilterChipBtn(
                      label: 'Tất cả (${allItems.length})',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipBtn(
                      label: 'Chờ duyệt ($pendingCount)',
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipBtn(
                      label: 'Đã duyệt ($approvedCount)',
                      selected: _filter == 'approved',
                      onTap: () => setState(() => _filter = 'approved'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _StateMessage(
                        message: 'Không có phiếu ĐRL nào trong mục này.',
                        onRetry: _reload,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _DrlCard(
                              item: item,
                              isApproving: _approvingIds.contains(item.id),
                              onApprove: item.isApproved ? null : () => _approve(item),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
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
        : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
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
                        fontWeight: FontWeight.w600,
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
                  item.isApproved ? 'Đã duyệt' : 'Chờ duyệt',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (item.updatedAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cập nhật: ${item.updatedAt}',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
          ],
          if (!item.isApproved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isApproving ? null : onApprove,
                icon: isApproving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Duyệt phiếu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ],
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
