import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/locale_service.dart';

enum AppErrorKind {
  network,
  server,
  auth,
  notFound,
  generic,
}

class ParsedAppError {
  const ParsedAppError({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  final AppErrorKind kind;
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
}

/// Phân tích thông điệp lỗi thô thành tiêu đề + mô tả tiếng Việt thân thiện
ParsedAppError parseFriendlyError(Object? error, {String? fallbackTitle}) {
  final raw = (error?.toString() ?? '').trim();
  final cleaned = raw
      .replaceFirst(RegExp(r'^(ApiException|Exception|FormatException):\s*'), '')
      .trim();
  final lower = cleaned.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('clientexception') ||
      lower.contains('không có kết nối') ||
      lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('quá thời gian')) {
    return ParsedAppError(
      kind: AppErrorKind.network,
      title: tr('Không thể kết nối mạng', 'No internet connection'),
      message: tr(
        'Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động 4G/5G rồi thử tải lại.',
        'Please check your Wi-Fi or mobile data and try again.',
      ),
      icon: Icons.wifi_off_rounded,
      accentColor: const Color(0xFFF59E0B),
    );
  }

  if (lower.contains('500') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('504') ||
      lower.contains('internal server') ||
      lower.contains('bad gateway') ||
      lower.contains('service unavailable')) {
    return ParsedAppError(
      kind: AppErrorKind.server,
      title: tr('Hệ thống đang tạm bận', 'Server is temporarily busy'),
      message: tr(
        'Máy chủ đang được bảo trì hoặc quá tải tạm thời. Vui lòng thử lại sau ít phút.',
        'The server is under maintenance or busy. Please try again in a few minutes.',
      ),
      icon: Icons.cloud_off_rounded,
      accentColor: const Color(0xFFEF4444),
    );
  }

  if (lower.contains('401') ||
      lower.contains('403') ||
      lower.contains('unauthorized') ||
      lower.contains('forbidden') ||
      lower.contains('không có quyền') ||
      lower.contains('hết hạn')) {
    return ParsedAppError(
      kind: AppErrorKind.auth,
      title: tr('Không thể xác thực truy cập', 'Authentication required'),
      message: tr(
        'Phiên đăng nhập đã hết hạn hoặc tài khoản chưa được cấp quyền xem mục này.',
        'Your session has expired or you do not have permission to view this page.',
      ),
      icon: Icons.lock_outline_rounded,
      accentColor: const Color(0xFF6366F1),
    );
  }

  if (lower.contains('404') || lower.contains('not found')) {
    return ParsedAppError(
      kind: AppErrorKind.notFound,
      title: tr('Không tìm thấy nội dung', 'Content not found'),
      message: tr(
        'Dữ liệu bạn yêu cầu có thể đã bị xóa hoặc không còn tồn tại.',
        'The requested data may have been removed or no longer exists.',
      ),
      icon: Icons.search_off_rounded,
      accentColor: const Color(0xFF64748B),
    );
  }

  final isTechnical = lower.contains('type \'') ||
      lower.contains('nosuchmethoderror') ||
      lower.contains('rangeerror') ||
      lower.contains('null check operator') ||
      lower.contains('formatexception') ||
      cleaned.isEmpty;

  return ParsedAppError(
    kind: AppErrorKind.generic,
    title: fallbackTitle ?? tr('Không thể tải dữ liệu', 'Unable to load data'),
    message: isTechnical
        ? tr(
            'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.',
            'An unexpected error occurred. Please try again later.',
          )
        : cleaned,
    icon: Icons.error_outline_rounded,
    accentColor: AppColors.danger,
  );
}

/// Giao diện lỗi chuẩn hóa cho các màn hình tải dữ liệu API / mạng (hỗ trợ Dark & Light Mode)
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.accentColor = AppColors.danger,
    this.onRetry,
    this.retryLabel, 
    this.compact = false,
  });

  factory AppErrorView.fromError(
    Object? error, {
    Key? key,
    String? fallbackTitle,
    VoidCallback? onRetry,
    String? retryLabel,
    bool compact = false,
  }) {
    final parsed = parseFriendlyError(error, fallbackTitle: fallbackTitle);
    return AppErrorView(
      key: key,
      title: parsed.title,
      message: parsed.message,
      icon: parsed.icon,
      accentColor: parsed.accentColor,
      onRetry: onRetry,
      retryLabel: retryLabel,
      compact: compact,
    );
  }

  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 24,
            vertical: compact ? 20 : 28,
          ),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.adaptiveBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.18 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 52 : 60,
                height: compact ? 52 : 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: AppColors.isDark ? 0.18 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: compact ? 26 : 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 15.5 : 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.adaptiveTextSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    retryLabel ?? tr('Thử lại', 'Try again'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
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

/// Màn hình hứng lỗi toàn cục thay thế Red Screen / Grey Screen của Flutter (`ErrorWidget.builder`).
/// Thiết kế tối giản, tự chủ để không bao giờ gây lỗi lồng nhau.
class GlobalErrorFallback extends StatelessWidget {
  const GlobalErrorFallback({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final nav = Navigator.maybeOf(context);
    final canPop = nav != null && nav.canPop();

    return Material(
      color: bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('Đã xảy ra sự cố hiển thị', 'Something went wrong'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Một thành phần trên trang gặp lỗi bất ngờ. Bạn có thể quay lại hoặc tải lại mục này.',
                      'A component on this screen encountered an unexpected error. Please go back or reload.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        details.exceptionAsString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (canPop) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => nav.maybePop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        tr('Quay lại', 'Go back'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
