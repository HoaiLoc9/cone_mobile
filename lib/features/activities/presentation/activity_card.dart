import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../data/activity_model.dart';
import 'activity_helpers.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.isMissingCheckout = false,
    this.onMissingCheckout,
  });

  final ActivityItem activity;
  final VoidCallback onTap;
  final bool isMissingCheckout;
  final VoidCallback? onMissingCheckout;

  @override
  Widget build(BuildContext context) {
    final isEnded = activity.isEnded;
    final isRegistered = activity.isRegistered;
    final canRegister = activity.canRegister;

    final Color statusColor;
    final String statusText;

    if (isEnded) {
      if (isRegistered) {
        if (isMissingCheckout) {
          statusColor = const Color(0xFFD97706);
          statusText = 'ĐÃ KẾT THÚC • THIẾU CHECK-OUT';
        } else {
          statusColor = const Color(0xFF10B981);
          statusText = 'ĐÃ HOÀN THÀNH';
        }
      } else {
        statusColor = const Color(0xFF64748B);
        statusText = 'ĐÃ KẾT THÚC';
      }
    } else if (isRegistered) {
      statusColor = const Color(0xFF10B981);
      statusText = 'ĐÃ ĐĂNG KÝ';
    } else if (canRegister) {
      statusColor = const Color(0xFF2563EB);
      statusText = 'ĐANG MỞ ĐĂNG KÝ';
    } else {
      statusColor = const Color(0xFF64748B);
      statusText = 'ĐÃ ĐÓNG ĐĂNG KÝ';
    }

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
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: (!isEnded && isRegistered)
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : AppColors.adaptiveBorder,
              width: (!isEnded && isRegistered) ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (!isEnded && isRegistered)
                    ? const Color(0xFF10B981).withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: AppColors.isDark ? 0.20 : 0.04),
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
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),

              // Thời gian tổ chức
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formatDateTime(activity.timeStart),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adaptiveTextSecondary,
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.adaptiveTextSecondary,
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
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adaptiveTextSecondary,
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
                    backgroundColor: AppColors.cardSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? const Color(0xFFEF4444)
                          : (isRegistered ? const Color(0xFF10B981) : AppColors.primary),
                    ),
                  ),
                ),
              ],
              if (isEnded && isRegistered && isMissingCheckout) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFFB45309),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: onMissingCheckout ?? onTap,
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text(
                      'Bổ sung check out',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
