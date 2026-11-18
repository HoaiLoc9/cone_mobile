import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../data/activity_model.dart';
import 'activity_helpers.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onTap});

  final ActivityItem activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRegistered = activity.isRegistered;
    final canRegister = activity.canRegister;

    final Color statusColor = isRegistered
        ? const Color(0xFF10B981)
        : (canRegister ? const Color(0xFF2563EB) : const Color(0xFF64748B));

    final String statusText = isRegistered
        ? 'ĐÃ ĐĂNG KÝ'
        : (canRegister ? 'ĐANG MỞ ĐĂNG KÝ' : 'ĐÃ ĐÓNG ĐĂNG KÝ');

    final double progress = (activity.maxRegistrations > 0)
        ? (activity.registeredCount / activity.maxRegistrations).clamp(0.0, 1.0)
        : 0.0;

    final String pointStr = activity.points.toStringAsFixed(
        activity.points.truncateToDouble() == activity.points ? 0 : 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRegistered
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
              width: isRegistered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isRegistered
                    ? const Color(0xFF10B981).withValues(alpha: 0.06)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng đỉnh: Trạng thái pill + Điểm ĐRL thưởng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          '+$pointStr ĐRL',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tiêu đề hoạt động
              Text(
                activity.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),

              // Thời gian tổ chức
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formatDateTime(activity.timeStart),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Địa điểm
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activity.location.isEmpty ? 'Chưa cập nhật địa điểm' : activity.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              if (activity.maxRegistrations > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã đăng ký ${activity.registeredCount}/${activity.maxRegistrations}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: progress >= 1.0 ? const Color(0xFFEF4444) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? const Color(0xFFEF4444)
                          : (isRegistered ? const Color(0xFF10B981) : AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
