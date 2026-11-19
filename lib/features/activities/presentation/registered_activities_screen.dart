import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../activity_support/data/activity_support_service.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';
import 'activity_detail_screen.dart';
import 'activity_helpers.dart';
import 'missing_checkout_sheet.dart';

class RegisteredActivitiesScreen extends StatefulWidget {
  const RegisteredActivitiesScreen({super.key, required this.service});

  final ActivityService service;

  @override
  State<RegisteredActivitiesScreen> createState() =>
      _RegisteredActivitiesScreenState();
}

class _RegisteredActivitiesScreenState
    extends State<RegisteredActivitiesScreen> {
  late Future<List<ActivityItem>> _future =
      widget.service.fetchRegisteredActivities();

  String _filter = 'all'; // 'all', 'attended', 'pending'

  void _reload() {
    setState(() => _future = widget.service.fetchRegisteredActivities());
  }

  Future<void> _openDetail(ActivityItem item) async {
    final updated = await Navigator.of(context).push<ActivityItem>(
      MaterialPageRoute(
        builder: (_) =>
            ActivityDetailScreen(service: widget.service, activityId: item.id),
      ),
    );
    if (updated != null) {
      _reload();
    }
  }

  String _points(double? points) {
    if (points == null) return '0';
    if (points == points.roundToDouble()) return points.toInt().toString();
    return points.toStringAsFixed(1);
  }

  Future<void> _openMissingCheckout(ActivityItem item) async {
    final supportService = ActivitySupportService(token: widget.service.token);
    final submitted = await MissingCheckoutSheet.show(
      context,
      service: supportService,
      activityId: item.id,
      activityName: item.name,
      timeStop: item.timeStop,
      location: item.location,
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu bổ sung check-out thành công! Quản trị viên sẽ xem xét duyệt.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Hoạt động đã đăng ký',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.adaptiveTextPrimary, fontSize: 18),
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
        child: FutureBuilder<List<ActivityItem>>(
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
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                      const SizedBox(height: 12),
                      const Text('Chưa tải được hoạt động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
                    ],
                  ),
                ),
              );
            }

            final allItems = snapshot.data ?? [];
            final attendedCount = allItems.where((i) => i.isRegistered && (i.registrationStatusLabel.contains('điểm danh') || i.registrationStatusLabel.contains('Hoàn thành'))).length;
            final pendingCount = allItems.length - attendedCount;

            final filteredItems = allItems.where((item) {
              if (_filter == 'attended') {
                return item.registrationStatusLabel.contains('điểm danh') || item.registrationStatusLabel.contains('Hoàn thành');
              }
              if (_filter == 'pending') {
                return !(item.registrationStatusLabel.contains('điểm danh') || item.registrationStatusLabel.contains('Hoàn thành'));
              }
              return true;
            }).toList();

            if (allItems.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 34),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa đăng ký hoạt động nào',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bạn có thể vào tab "Hoạt động" để khám phá và đăng ký các sự kiện rèn luyện đang mở.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Thẻ tổng kết số lượng
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Tổng đăng ký',
                          value: '${allItems.length}',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Đã điểm danh',
                          value: '$attendedCount',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Chờ tham gia',
                          value: '$pendingCount',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bộ lọc Tab nhanh
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('Tất cả (${allItems.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Đã điểm danh ($attendedCount)', 'attended'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Chờ tham gia ($pendingCount)', 'pending'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Không có hoạt động trong danh mục này.',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRegisteredCard(item),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.adaptiveTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
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

  Widget _buildRegisteredCard(ActivityItem item) {
    final isAttended = item.registrationStatusLabel.contains('điểm danh') ||
        item.registrationStatusLabel.contains('Hoàn thành');
    final isEnded = item.isEnded;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (isAttended) {
      statusColor = const Color(0xFF10B981);
      statusText = 'ĐÃ HOÀN THÀNH';
      statusIcon = Icons.check_circle_rounded;
    } else if (isEnded) {
      statusColor = const Color(0xFFD97706);
      statusText = 'ĐÃ KẾT THÚC • CHƯA CHECK-OUT';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF2563EB);
      statusText = 'ĐÃ ĐĂNG KÝ';
      statusIcon = Icons.schedule_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(item),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAttended
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : (isEnded
                      ? const Color(0xFFD97706).withValues(alpha: 0.35)
                      : AppColors.adaptiveBorder),
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
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      '+${_points(item.points)} ĐRL',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.adaptiveTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${formatDateTime(item.timeStart)} - ${formatDateTime(item.timeStop)}',
                      style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.location.isEmpty ? 'Chưa cập nhật địa điểm' : item.location,
                      style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (isEnded && !isAttended) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFFB45309),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () => _openMissingCheckout(item),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text(
                      'Bổ sung check out',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.adaptiveBorder),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Xem chi tiết hoạt động',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
