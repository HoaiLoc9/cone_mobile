// ignore_for_file: sort_child_properties_last, use_null_aware_elements

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/student_services_service.dart';
import 'topcv_builder_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late Future<List<StudentComplaint>> _future = widget.service.complaints();
  String _filter = 'all'; // 'all', 'pending', 'resolved'

  void _reload() => setState(() => _future = widget.service.complaints());

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Khiếu nại & Phản hồi',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.adaptiveAppBarBg,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo khiếu nại',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<StudentComplaint>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa tải được danh sách khiếu nại',
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

            final allItems = snapshot.data ?? [];
            final pendingCount = allItems.where((i) => i.response.isEmpty).length;
            final resolvedCount = allItems.where((i) => i.response.isNotEmpty).length;

            final filteredItems = allItems.where((item) {
              if (_filter == 'pending') return item.response.isEmpty;
              if (_filter == 'resolved') return item.response.isNotEmpty;
              return true;
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Thẻ hướng dẫn quy trình
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quyền lợi & Phúc khảo rèn luyện',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Nếu điểm hoạt động hoặc điểm rèn luyện chưa chính xác, bạn hãy gửi khiếu nại để Ban quản lý và Cán bộ xác minh giải quyết.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bộ lọc Tab
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Tất cả (${allItems.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Chờ phản hồi ($pendingCount)', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Đã giải quyết ($resolvedCount)', 'resolved'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              allItems.isEmpty ? 'Chưa có đơn khiếu nại nào' : 'Không có đơn trong danh mục này',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.adaptiveTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút "Tạo khiếu nại" bên dưới khi bạn cần phản ánh.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.adaptiveTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildComplaintCard(item),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.adaptiveBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.adaptiveTextSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(StudentComplaint item) {
    final hasResponse = item.response.isNotEmpty;
    final statusColor = hasResponse ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusBg = hasResponse ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final statusLabel = hasResponse ? 'ĐÃ PHẢN HỒI' : 'CHỜ XỬ LÝ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasResponse
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : AppColors.adaptiveBorder,
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasResponse ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.report_problem_outlined, size: 14, color: AppColors.adaptiveTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Đơn phản ánh',
                    style: TextStyle(fontSize: 11.5, color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            item.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.content,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.adaptiveTextSecondary,
              height: 1.4,
            ),
          ),

          if (hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Phản hồi từ Nhà trường / Cán bộ:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.response,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Ban Quản lý đang tiếp nhận hồ sơ và sẽ phản hồi sớm nhất.',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.adaptiveTextSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class PermissionRequestsScreen extends StatefulWidget {
  const PermissionRequestsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<PermissionRequestsScreen> createState() =>
      _PermissionRequestsScreenState();
}

class _PermissionRequestsScreenState extends State<PermissionRequestsScreen> {
  late Future<List<PermissionRequestItem>> _future = widget.service.permissionRequests();
  String _filter = 'all';

  void _reload() => setState(() => _future = widget.service.permissionRequests());

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  void _showEvidenceDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Minh chứng đính kèm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.adaptiveTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.adaptiveTextSecondary),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (ctx, err, stack) {
                    return Container(
                      height: 160,
                      color: AppColors.adaptiveBorder.withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 40, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Tài liệu minh chứng đã được lưu trữ.',
                            style: TextStyle(fontSize: 13, color: AppColors.adaptiveTextPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.adaptiveBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.adaptiveTextSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionRequestItem item) {
    final isApproved = item.status == 'approved';
    final isRejected = item.status == 'rejected';
    final statusColor = isApproved
        ? const Color(0xFF10B981)
        : isRejected
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final statusBg = isApproved
        ? const Color(0xFFD1FAE5)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final statusLabel = isApproved
        ? 'ĐÃ DUYỆT'
        : isRejected
            ? 'TỪ CHỐI'
            : 'CHỜ DUYỆT';

    final isAbsence = item.type == 'absence';
    final isMakeup = item.type == 'makeup';
    final typeBadgeColor = isAbsence
        ? const Color(0xFF6366F1)
        : isMakeup
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF0EA5E9);
    final typeBadgeBg = typeBadgeColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : isRejected
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : AppColors.adaptiveBorder,
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: typeBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAbsence
                          ? Icons.event_busy_rounded
                          : isMakeup
                              ? Icons.update_rounded
                              : Icons.verified_user_rounded,
                      size: 13,
                      color: typeBadgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.typeLabel.isNotEmpty ? item.typeLabel : 'Xin phép',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: typeBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved
                          ? Icons.check_circle_rounded
                          : isRejected
                              ? Icons.cancel_rounded
                              : Icons.hourglass_top_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.reason,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.adaptiveTextSecondary,
              height: 1.4,
            ),
          ),
          if (item.evidenceUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showEvidenceDialog(context, item.evidenceUrl),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.adaptiveBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attachment_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Xem minh chứng đính kèm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
          if (item.adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isApproved
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : isRejected
                        ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                        : (AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isApproved
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : isRejected
                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                          : AppColors.adaptiveBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 15,
                        color: isApproved
                            ? const Color(0xFF10B981)
                            : isRejected
                                ? const Color(0xFFEF4444)
                                : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phản hồi từ Cán bộ quản lý:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.adminNote,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.adaptiveTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Ban Quản lý đang tiếp nhận và xem xét giải quyết hồ sơ.',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.adaptiveTextSecondary),
            ),
          ],
          if (item.createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Thời gian: ${item.createdAt}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.adaptiveTextSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.adaptiveTextPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Giấy xin phép',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextPrimary),
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo giấy mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PermissionRequestItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa tải được giấy xin phép',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.adaptiveTextSecondary, fontSize: 13),
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

            final allItems = snapshot.data ?? [];
            final pendingCount = allItems.where((i) => i.status == 'pending').length;
            final approvedCount = allItems.where((i) => i.status == 'approved').length;
            final rejectedCount = allItems.where((i) => i.status == 'rejected').length;

            final filteredItems = allItems.where((item) {
              if (_filter == 'pending') return item.status == 'pending';
              if (_filter == 'approved') return item.status == 'approved';
              if (_filter == 'rejected') return item.status == 'rejected';
              return true;
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Thẻ hướng dẫn quy trình
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment_ind_rounded, color: Colors.lightBlueAccent, size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quy trình Xin phép trực tuyến',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Nộp đơn xin vắng hoạt động, bù hoạt động hoặc miễn hoạt động rèn luyện. Kèm theo minh chứng để được xét duyệt nhanh nhất.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bộ lọc Tab
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Tất cả (${allItems.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Chờ duyệt ($pendingCount)', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Đã duyệt ($approvedCount)', 'approved'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Từ chối ($rejectedCount)', 'rejected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              allItems.isEmpty ? 'Chưa có giấy xin phép nào' : 'Không có giấy trong danh mục này',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.adaptiveTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút "Tạo giấy mới" bên dưới khi bạn cần nộp đơn.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.adaptiveTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPermissionCard(item),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<StudentDocument>> _future = widget.service.documents();

  void _reload() => setState(() => _future = widget.service.documents());

  Future<void> _upload() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DocumentForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Tài liệu hồ sơ',
      subtitle: 'Upload tài liệu và xem trạng thái duyệt',
      action: IconButton(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file),
      ),
      child: FutureBuilder<List<StudentDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được tài liệu',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return AppStateView(
              icon: Icons.folder_open_outlined,
              title: 'Chưa có tài liệu',
              message: 'Upload hồ sơ hoặc minh chứng để admin duyệt.',
              actionLabel: 'Upload',
              onAction: _upload,
            );
          }
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.title,
                  subtitle: item.type,
                  status: item.statusLabel,
                  note: item.adminNote.isEmpty
                      ? 'Chưa có ghi chú.'
                      : item.adminNote,
                  icon: Icons.description_outlined,
                  footer: item.fileUrl.isEmpty ? null : 'File: ${item.fileUrl}',
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}

class ProfileStatusScreen extends StatelessWidget {
  const ProfileStatusScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Trạng thái hồ sơ',
      subtitle: 'Tình trạng hồ sơ cá nhân và ghi chú admin',
      child: FutureBuilder<ProfileStatus>(
        future: service.profileStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được trạng thái hồ sơ',
              message: snapshot.error.toString(),
            );
          }
          final status = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              COneCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(status.statusLabel),
                    const SizedBox(height: 18),
                    const Text(
                      'Ghi chú xử lý',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.note.isEmpty
                          ? 'Chưa có ghi chú từ admin.'
                          : status.note,
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CvScreen extends StatelessWidget {
  const CvScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  Widget build(BuildContext context) {
    return TopCvBuilderScreen(service: service);
  }
}

class CvEditorScreen extends StatelessWidget {
  const CvEditorScreen({super.key, required this.service, required this.cv});

  final StudentServicesService service;
  final CvDocument cv;

  @override
  Widget build(BuildContext context) {
    return TopCvEditorScreen(service: service, cv: cv);
  }
}

class ActivitySuggestionsScreen extends StatelessWidget {
  const ActivitySuggestionsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Gợi ý hoạt động',
      subtitle: 'Hoạt động phù hợp để cải thiện điểm rèn luyện',
      child: FutureBuilder<List<ActivitySuggestion>>(
        future: service.activitySuggestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được gợi ý',
              message: snapshot.error.toString(),
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.lightbulb_outline,
              title: 'Chưa có gợi ý',
              message:
                  'Hệ thống chưa tìm thấy hoạt động phù hợp tại thời điểm này.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.name,
                  subtitle: item.reasons.isEmpty
                      ? 'Phù hợp với hồ sơ hiện tại.'
                      : item.reasons.join('\n'),
                  status: '+${item.score} điểm',
                  note: 'Bạn có thể vào mục Hoạt động để xem và đăng ký.',
                  icon: Icons.lightbulb_outline,
                ),
            ],
          );
        },
      ),
    );
  }
}

class SignatureRequestsScreen extends StatefulWidget {
  const SignatureRequestsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<SignatureRequestsScreen> createState() =>
      _SignatureRequestsScreenState();
}

class _SignatureRequestsScreenState extends State<SignatureRequestsScreen> {
  late Future<List<SignatureRequestItem>> _future = widget.service
      .signatureRequests();

  void _reload() =>
      setState(() => _future = widget.service.signatureRequests());

  Future<void> _open(SignatureRequestItem item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SignatureRequestDetailScreen(service: widget.service, item: item),
      ),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Chữ ký số',
      subtitle: 'Hồ sơ cần ký và canvas ký tên',
      child: FutureBuilder<List<SignatureRequestItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: ShimmerListLoading(itemCount: 4));
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được hồ sơ cần ký',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.draw_outlined,
              title: 'Chưa có hồ sơ cần ký',
              message:
                  'Khi admin yêu cầu ký hồ sơ, danh sách sẽ hiển thị tại đây.',
            );
          }
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.title.isEmpty ? 'Hồ sơ cần ký' : item.title,
                  subtitle: item.description,
                  status: item.statusLabel,
                  note: item.mayBeSigned
                      ? 'Có thể ký ngay trên điện thoại.'
                      : 'Hồ sơ chưa mở để ký hoặc đã xử lý.',
                  icon: Icons.draw_outlined,
                  footer: item.documentOriginalName.isEmpty
                      ? null
                      : 'Tệp: ${item.documentOriginalName}',
                  onTap: () => _open(item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class SignatureRequestDetailScreen extends StatefulWidget {
  const SignatureRequestDetailScreen({
    super.key,
    required this.service,
    required this.item,
  });

  final StudentServicesService service;
  final SignatureRequestItem item;

  @override
  State<SignatureRequestDetailScreen> createState() =>
      _SignatureRequestDetailScreenState();
}

class _SignatureRequestDetailScreenState
    extends State<SignatureRequestDetailScreen> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _acknowledgement = false;
  bool _saving = false;
  String? _error;

  void _clear() => setState(_points.clear);

  Future<String?> _signaturePngDataUrl() async {
    if (_points.whereType<Offset>().isEmpty) return null;
    final boundary =
        _signatureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.5);
    final bytes = await image?.toByteData(format: ui.ImageByteFormat.png);
    final data = bytes?.buffer.asUint8List();
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data)}';
  }

  Future<void> _sign() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final signatureData = await _signaturePngDataUrl();
      if (signatureData == null) {
        setState(
          () => _error = 'Vui lòng ký trên vùng trắng trước khi xác nhận.',
        );
        return;
      }
      await widget.service.signSignatureRequest(
        id: widget.item.id,
        signatureData: signatureData,
        acknowledgement: _acknowledgement,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return _ServiceScaffold(
      title: 'Ký hồ sơ',
      subtitle: item.title,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _InfoCard(
            title: item.title.isEmpty ? 'Hồ sơ cần ký' : item.title,
            subtitle: item.description,
            status: item.statusLabel,
            note: item.acknowledgementText.isEmpty
                ? 'Vui lòng đọc kỹ hồ sơ trước khi ký.'
                : item.acknowledgementText,
            icon: Icons.assignment_outlined,
            footer: item.documentUrl.isEmpty
                ? null
                : 'Link hồ sơ: ${item.documentUrl}',
          ),
          const SizedBox(height: 12),
          COneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ký tên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                RepaintBoundary(
                  key: _signatureKey,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final box =
                          _signatureKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      final offset = box?.globalToLocal(details.globalPosition);
                      if (offset != null) setState(() => _points.add(offset));
                    },
                    onPanUpdate: (details) {
                      final box =
                          _signatureKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      final offset = box?.globalToLocal(details.globalPosition);
                      if (offset != null) setState(() => _points.add(offset));
                    },
                    onPanEnd: (_) => setState(() => _points.add(null)),
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.adaptiveBorder),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: _acknowledgement,
                        onChanged: item.mayBeSigned
                            ? (value) => setState(
                                () => _acknowledgement = value ?? false,
                              )
                            : null,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Tôi đã đọc và đồng ý với nội dung hồ sơ.',
                        ),
                      ),
                    ),
                    TextButton(onPressed: _clear, child: const Text('Xóa ký')),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Ký xác nhận',
                  onPressed: item.mayBeSigned ? _sign : null,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  const _ComplaintForm({required this.service});

  final StudentServicesService service;

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final content = _content.text.trim();

    if (title.length < 2) {
      setState(() => _error = 'Tiêu đề khiếu nại cần tối thiểu 2 ký tự.');
      return;
    }
    if (content.length < 3) {
      setState(() => _error = 'Nội dung chi tiết cần tối thiểu 3 ký tự.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.createComplaint(
        title: title,
        content: content,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Gửi đơn khiếu nại rèn luyện',
      subtitle: 'Nêu rõ ý kiến khiếu nại về điểm rèn luyện hoặc hoạt động',
      error: _error,
      children: [
        AppTextField(
          controller: _title,
          label: 'Tiêu đề khiếu nại',
          hint: 'Ví dụ: Phúc khảo điểm hoạt động Chào tân sinh viên (tối thiểu 2 ký tự)',
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _content,
          label: 'Nội dung chi tiết',
          hint: 'Trình bày rõ lý do, thời gian tham gia và đề xuất của bạn... (tối thiểu 3 ký tự)',
          icon: Icons.notes_rounded,
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Gửi khiếu nại ngay', onPressed: _submit, isLoading: _saving),
      ],
    );
  }
}

class _PermissionForm extends StatefulWidget {
  const _PermissionForm({required this.service});

  final StudentServicesService service;

  @override
  State<_PermissionForm> createState() => _PermissionFormState();
}

class _PermissionFormState extends State<_PermissionForm> {
  final _title = TextEditingController();
  final _reason = TextEditingController();
  String _type = 'absence';
  FilePayload? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(() => _file = FilePayload(name: compressed.name, bytes: compressed.bytes));
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final reason = _reason.text.trim();

    if (title.length < 2) {
      setState(() => _error = 'Tiêu đề cần tối thiểu 2 ký tự.');
      return;
    }
    if (reason.length < 3) {
      setState(() => _error = 'Lý do cần tối thiểu 3 ký tự.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.createPermissionRequest(
        type: _type,
        title: title,
        reason: reason,
        evidence: _file,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildTypeOption(String value, String label, IconData icon) {
    final selected = _type == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.adaptiveBorder,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.adaptiveTextSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Tạo giấy xin phép',
      subtitle: 'Điền thông tin và đính kèm minh chứng để gửi Ban Quản lý',
      error: _error,
      children: [
        // Chọn loại giấy
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loại giấy xin phép',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeOption('absence', 'Vắng hoạt động', Icons.event_busy_rounded),
                const SizedBox(width: 8),
                _buildTypeOption('makeup', 'Bù hoạt động', Icons.update_rounded),
                const SizedBox(width: 8),
                _buildTypeOption('exemption', 'Miễn hoạt động', Icons.verified_user_rounded),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        AppTextField(
          controller: _title,
          label: 'Tiêu đề đơn',
          hint: 'Ví dụ: Xin phép vắng buổi sinh hoạt (tối thiểu 2 ký tự)...',
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          controller: _reason,
          label: 'Lý do xin phép chi tiết',
          hint: 'Nêu rõ lý do (tối thiểu 3 ký tự, ví dụ: bị bệnh sốt siêu vi, trùng lịch thi...)...',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Chọn minh chứng
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài liệu minh chứng (tùy chọn)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_file == null)
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.adaptiveBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đính kèm minh chứng / ảnh giấy tờ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hỗ trợ JPG, PNG, PDF (tối đa 8MB)',
                        style: TextStyle(fontSize: 11, color: AppColors.adaptiveTextSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _file!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_file!.bytes.length / 1024).toStringAsFixed(1)} KB • Sẵn sàng gửi',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _file = null),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
                      tooltip: 'Hủy chọn file',
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        PrimaryButton(
          label: 'Gửi giấy xin phép',
          onPressed: _submit,
          isLoading: _saving,
        ),
      ],
    );
  }
}

class _DocumentForm extends StatefulWidget {
  const _DocumentForm({required this.service});

  final StudentServicesService service;

  @override
  State<_DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<_DocumentForm> {
  final _title = TextEditingController();
  final _type = TextEditingController(text: 'profile');
  FilePayload? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(() => _file = FilePayload(name: compressed.name, bytes: compressed.bytes));
  }

  Future<void> _submit() async {
    if (_file == null) {
      setState(() => _error = 'Vui lòng chọn tài liệu cần upload.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.uploadDocument(
        title: _title.text.trim(),
        type: _type.text.trim(),
        file: _file!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Upload tài liệu',
      error: _error,
      children: [
        AppTextField(
          controller: _title,
          label: 'Tên tài liệu',
          hint: 'CMND/CCCD, giấy xác nhận...',
          icon: Icons.title,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _type,
          label: 'Loại tài liệu',
          hint: 'profile/evidence/other',
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: Text(_file == null ? 'Chọn file' : _file!.name),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Upload', onPressed: _submit, isLoading: _saving),
      ],
    );
  }
}

class _ServiceScaffold extends StatelessWidget {
  const _ServiceScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [if (action != null) action!],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Text(
                subtitle,
                style: TextStyle(color: AppColors.adaptiveTextSecondary),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: children,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.note,
    required this.icon,
    this.footer,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final String note;
  final IconData icon;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: COneCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? 'Đang xử lý' : label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.children,
    this.subtitle,
    this.error,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.adaptiveBorder, width: 1.2),
          left: BorderSide(color: AppColors.adaptiveBorder, width: 0.5),
          right: BorderSide(color: AppColors.adaptiveBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo gạt ở đỉnh
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tiêu đề + Nút đóng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.adaptiveTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.cardSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.adaptiveTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ...children,
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBlue
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.2;
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}



