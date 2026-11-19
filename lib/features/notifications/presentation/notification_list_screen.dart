import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/local_notification_service.dart';
import '../../activities/data/activity_service.dart';
import '../../activities/presentation/activity_detail_screen.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../../activities/presentation/activity_list_screen.dart';
import '../../appellations/data/appellation_service.dart';
import '../../appellations/presentation/appellation_detail_screen.dart';
import '../../appellations/presentation/appellation_list_screen.dart';
import '../../drl/data/drl_service.dart';
import '../../drl/presentation/drl_summary_screen.dart';
import '../data/notification_models.dart';
import '../data/notification_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key, required this.service});

  final NotificationService service;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  bool _isLoading = true;
  bool _unreadOnly = false;
  String? _selectedType;
  String? _errorMessage;
  NotificationList? _list;

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
      final list = await widget.service.fetchNotifications(
        type: _selectedType,
        unreadOnly: _unreadOnly,
      );
      if (mounted) setState(() => _list = list);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Không tải được thông báo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.id.isEmpty) return;
    await widget.service.markRead(item.id);
    _load();
  }

  Future<void> _markAllRead() async {
    await widget.service.markAllRead();
    _load();
  }

  bool _isActivityNotification(AppNotification item) {
    final t = item.type.toLowerCase();
    final title = item.title.toLowerCase();
    final msg = item.message.toLowerCase();
    return t.contains('activity') ||
        t.contains('hoat_dong') ||
        item.meta.containsKey('activity_id') ||
        item.meta.containsKey('activityId') ||
        item.meta.containsKey('activity') ||
        title.contains('hoạt động') ||
        msg.contains('hoạt động');
  }

  String? _extractActivityId(AppNotification item) {
    if (item.meta['activity_id'] != null &&
        item.meta['activity_id'].toString().isNotEmpty) {
      return item.meta['activity_id'].toString();
    }
    if (item.meta['activityId'] != null &&
        item.meta['activityId'].toString().isNotEmpty) {
      return item.meta['activityId'].toString();
    }
    if (item.meta['activity'] is Map &&
        (item.meta['activity']['id'] != null)) {
      return item.meta['activity']['id'].toString();
    }
    return null;
  }

  bool _isAppellationNotification(AppNotification item) {
    final t = item.type.toLowerCase();
    final title = item.title.toLowerCase();
    final msg = item.message.toLowerCase();
    return t.contains('appellation') ||
        t.contains('danh_hieu') ||
        item.meta.containsKey('appellation_id') ||
        item.meta.containsKey('appellationId') ||
        item.meta.containsKey('appellation') ||
        title.contains('danh hiệu') ||
        msg.contains('danh hiệu');
  }

  String? _extractAppellationId(AppNotification item) {
    if (item.meta['appellation_id'] != null &&
        item.meta['appellation_id'].toString().isNotEmpty) {
      return item.meta['appellation_id'].toString();
    }
    if (item.meta['appellationId'] != null &&
        item.meta['appellationId'].toString().isNotEmpty) {
      return item.meta['appellationId'].toString();
    }
    if (item.meta['appellation'] is Map &&
        (item.meta['appellation']['id'] != null)) {
      return item.meta['appellation']['id'].toString();
    }
    return null;
  }

  bool _isDrlNotification(AppNotification item) {
    final t = item.type.toLowerCase();
    final title = item.title.toLowerCase();
    final msg = item.message.toLowerCase();
    return t.contains('drl') ||
        t.contains('diem_ren_luyen') ||
        item.meta.containsKey('drl') ||
        title.contains('điểm rèn luyện') ||
        title.contains('đrl') ||
        msg.contains('điểm rèn luyện') ||
        msg.contains('đrl');
  }

  void _handleNotificationTap(AppNotification item) {
    if (!item.isRead) {
      _markRead(item);
    }

    final token = widget.service.token;

    // 1. Hoạt động
    if (_isActivityNotification(item)) {
      final actId = _extractActivityId(item);
      if (actId != null && actId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(
              activityId: actId,
              service: ActivityService(token: token),
            ),
          ),
        );
        return;
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityListScreen(
              service: ActivityService(token: token),
            ),
          ),
        );
        return;
      }
    }

    // 2. Danh hiệu
    if (_isAppellationNotification(item)) {
      final appId = _extractAppellationId(item);
      if (appId != null && appId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppellationDetailScreen(
              appellationId: appId,
              service: AppellationService(token: token),
            ),
          ),
        );
        return;
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppellationListScreen(
              service: AppellationService(token: token),
            ),
          ),
        );
        return;
      }
    }

    // 3. Điểm rèn luyện
    if (_isDrlNotification(item)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DrlSummaryScreen(
            service: DrlService(token: token),
          ),
        ),
      );
      return;
    }

    // 4. Khác -> Mở chi tiết
    _showDetail(item);
  }

  void _showDetail(AppNotification item) {
    if (!item.isRead) {
      _markRead(item);
    }

    final color = _colorForType(item.type);
    final icon = _iconForType(item.type);
    final typeName = _typeName(item.type);
    final isActivity = _isActivityNotification(item);
    final isAppellation = _isAppellationNotification(item);
    final isDrl = _isDrlNotification(item);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeName,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          compactDate(item.createdAt),
                          style: TextStyle(
                            color: AppColors.adaptiveTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.adaptiveCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.adaptiveBorder),
                ),
                child: Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (isActivity || isAppellation || isDrl) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleNotificationTap(item);
                    },
                    icon: Icon(
                      isActivity
                          ? Icons.event_available_rounded
                          : isAppellation
                              ? Icons.emoji_events_rounded
                              : Icons.insights_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isActivity
                          ? 'Mở hoạt động này'
                          : isAppellation
                              ? 'Mở danh hiệu này'
                              : 'Xem điểm rèn luyện',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.adaptiveTextSecondary,
                    side: BorderSide(color: AppColors.adaptiveBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeName(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('activity') || lower.contains('hoat_dong')) {
      return 'HOẠT ĐỘNG';
    }
    if (lower.contains('appellation') || lower.contains('danh_hieu')) {
      if (lower.contains('approved')) return 'DANH HIỆU ĐẠT';
      if (lower.contains('rejected')) return 'DANH HIỆU KHÔNG ĐẠT';
      if (lower.contains('needs_revision') || lower.contains('revision')) return 'CẦN BỔ SUNG';
      return 'DANH HIỆU';
    }
    if (lower.contains('drl')) {
      if (lower.contains('deduction')) return 'TRỪ ĐIỂM DRL';
      if (lower.contains('award')) return 'CỘNG ĐIỂM DRL';
      return 'ĐIỂM RÈN LUYỆN';
    }
    return 'HỆ THỐNG';
  }

  Color _colorForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('deduction') || lower.contains('rejected')) {
      return AppColors.danger;
    }
    if (lower.contains('award') || lower.contains('approved')) {
      return const Color(0xFF059669);
    }
    if (lower.contains('revision') || lower.contains('needs_revision')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('appellation') || lower.contains('danh_hieu')) {
      return const Color(0xFF8B5CF6);
    }
    return AppColors.primary;
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('activity') || lower.contains('hoat_dong')) {
      return Icons.event_available_rounded;
    }
    if (lower.contains('appellation') || lower.contains('danh_hieu')) {
      return Icons.emoji_events_rounded;
    }
    if (lower.contains('deduction')) {
      return Icons.remove_circle_outline_rounded;
    }
    if (lower.contains('award')) {
      return Icons.add_circle_outline_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  String _actionTextForNotification(AppNotification item) {
    if (_isActivityNotification(item)) {
      return 'Mở hoạt động >';
    }
    if (_isAppellationNotification(item)) {
      return 'Xem danh hiệu >';
    }
    if (_isDrlNotification(item)) {
      return 'Xem điểm ĐRL >';
    }
    return 'Xem chi tiết >';
  }

  void _onCategorySelected(String? type, bool unreadOnly) {
    setState(() {
      _selectedType = type;
      _unreadOnly = unreadOnly;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final unreadCount = list?.unreadCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: AppColors.adaptiveAppBarBg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'Thông báo',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.adaptiveTextPrimary),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount mới',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text(
                  'Đọc tất cả',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Thẻ Bật Thông Báo Đẩy Nổi Bật
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _DeviceNotificationBanner(service: widget.service),
                ),
              ),

              // 2. Thanh Danh Mục Bộ Lọc Trượt Ngang (Horizontal Filter Pills)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Tất cả',
                        isSelected: !_unreadOnly && _selectedType == null,
                        icon: Icons.all_inbox_rounded,
                        onTap: () => _onCategorySelected(null, false),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Chưa đọc',
                        badgeCount: unreadCount > 0 ? unreadCount : null,
                        isSelected: _unreadOnly,
                        icon: Icons.mark_chat_unread_outlined,
                        onTap: () => _onCategorySelected(null, true),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Hoạt động',
                        isSelected: !_unreadOnly && _selectedType == 'activity',
                        icon: Icons.event_note_rounded,
                        onTap: () => _onCategorySelected('activity', false),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Danh hiệu',
                        isSelected: !_unreadOnly && _selectedType == 'appellation',
                        icon: Icons.emoji_events_rounded,
                        onTap: () => _onCategorySelected('appellation', false),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Điểm ĐRL',
                        isSelected: !_unreadOnly && _selectedType == 'drl',
                        icon: Icons.assessment_rounded,
                        onTap: () => _onCategorySelected('drl', false),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Hệ thống',
                        isSelected: !_unreadOnly && _selectedType == 'system',
                        icon: Icons.settings_rounded,
                        onTap: () => _onCategorySelected('system', false),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 3. Trạng Thái Đang Tải / Lỗi / Danh Sách Rỗng
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyStateView(
                    icon: Icons.wifi_off_rounded,
                    title: 'Lỗi tải thông báo',
                    subtitle: _errorMessage!,
                    buttonLabel: 'Thử lại',
                    onButtonTap: _load,
                  ),
                )
              else if (list == null || list.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyStateView(
                    icon: Icons.notifications_off_rounded,
                    title: _unreadOnly
                        ? 'Không có thông báo chưa đọc'
                        : 'Bạn chưa có thông báo nào',
                    subtitle: _unreadOnly
                        ? 'Tuyệt vời! Bạn đã xem hết tất cả thông báo.'
                        : 'Các thông báo hoạt động, điểm rèn luyện sẽ hiển thị tại đây.',
                  ),
                )
              else
                // 4. Danh Sách Thông Báo Đã Thiết Kế Lại Hiện Đại
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = list.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationCard(
                            item: item,
                            actionText: _actionTextForNotification(item),
                            onTap: () => _handleNotificationTap(item),
                            onMarkRead: () => _markRead(item),
                          ),
                        );
                      },
                      childCount: list.items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút lọc danh mục (Pill Button) phong cách hiện đại
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.adaptiveTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.adaptiveTextPrimary,
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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

/// Thẻ kích hoạt Thông báo đẩy thiết kế phong cách Apple / Glassmorphism
class _DeviceNotificationBanner extends StatefulWidget {
  const _DeviceNotificationBanner({required this.service});

  final NotificationService service;

  @override
  State<_DeviceNotificationBanner> createState() => _DeviceNotificationBannerState();
}

class _DeviceNotificationBannerState extends State<_DeviceNotificationBanner> {
  String _permissionStatus = 'default';
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    final status = LocalNotificationService.instance.checkWebPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });
    if (status == 'granted') {
      _syncPushToken();
    }
  }

  Future<void> _syncPushToken() async {
    try {
      final sub = await LocalNotificationService.instance.getPushSubscription();
      if (sub != null && mounted) {
        await widget.service.registerPushSubscription(sub);
      }
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final res = await LocalNotificationService.instance.requestUniversalPermission();
    if (mounted) {
      setState(() {
        _permissionStatus = res;
        _isRequesting = false;
      });
      if (res == 'granted') {
        _syncPushToken();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã kích hoạt nhận thông báo đẩy thành công! 🎉'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        await LocalNotificationService.instance.showNotification(
          title: 'COne Thông Báo 🔔',
          body: 'Thiết bị của bạn đã sẵn sàng nhận thông báo điểm rèn luyện & sự kiện!',
        );
      } else if (res == 'denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền thông báo bị từ chối. Trên iPhone: Vào Cài đặt > Thông báo > COne để bật.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    await LocalNotificationService.instance.showNotification(
      title: 'COne Thử Nghiệm 🔔',
      body: 'Thông báo đẩy trên iPhone hoạt động rất tốt!',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo thử nghiệm tới màn hình!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGranted = _permissionStatus == 'granted';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGranted
              ? [const Color(0xFF0F766E), const Color(0xFF059669)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isGranted ? const Color(0xFF059669) : AppColors.primary).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isGranted ? Icons.notifications_active_rounded : Icons.cell_tower_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGranted ? 'Thông báo đẩy: ĐÃ SẴN SÀNG' : 'Thông báo đẩy lên thiết bị',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGranted
                              ? 'Nhận tin báo điểm rèn luyện & điểm danh ngay tức thì.'
                              : 'Bật nhận thông báo ngay cả khi đã tắt app.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (isGranted) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text(
                          'Gửi thử thông báo lên máy',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isRequesting ? null : _requestPermission,
                        icon: _isRequesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.touch_app_rounded, size: 18),
                        label: Text(
                          _isRequesting ? 'Đang yêu cầu...' : 'Kích hoạt thông báo ngay',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ thông báo từng mục với thiết kế tinh tế, thẻ bo góc nhẹ, chỉ báo chưa đọc
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.actionText,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification item;
  final String actionText;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  Color _colorForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('deduction') || lower.contains('rejected')) {
      return AppColors.danger;
    }
    if (lower.contains('award') || lower.contains('approved')) {
      return const Color(0xFF059669);
    }
    if (lower.contains('revision') || lower.contains('needs_revision')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('appellation') || lower.contains('danh_hieu')) {
      return const Color(0xFF8B5CF6);
    }
    return AppColors.primary;
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('activity') || lower.contains('hoat_dong')) {
      return Icons.event_available_rounded;
    }
    if (lower.contains('appellation') || lower.contains('danh_hieu')) {
      return Icons.emoji_events_rounded;
    }
    if (lower.contains('deduction')) {
      return Icons.remove_circle_outline_rounded;
    }
    if (lower.contains('award')) {
      return Icons.add_circle_outline_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(item.type);
    final isUnread = !item.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? color.withValues(alpha: 0.05) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
              width: isUnread ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon biểu trưng
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForType(item.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.adaptiveTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          compactDate(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          actionText,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trạng thái rỗng / Lỗi
class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.adaptiveTextSecondary,
                height: 1.4,
              ),
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onButtonTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
