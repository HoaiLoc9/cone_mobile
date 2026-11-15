import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../activities/presentation/activity_helpers.dart';
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
      setState(() => _list = list);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được thông báo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.id.isEmpty) {
      return;
    }
    await widget.service.markRead(item.id);
    _load();
  }

  Future<void> _markAllRead() async {
    await widget.service.markAllRead();
    _load();
  }

  void _showDetail(AppNotification item) {
    if (!item.isRead) {
      _markRead(item);
    }

    final color = _colorForType(item.type);
    final icon = _iconForType(item.type);
    final typeName = _typeName(item.type);

    showModalBottomSheet<void>(
      context: context,
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                item.title.isEmpty ? 'Chi tiết thông báo' : item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              if (item.meta.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((item.meta['activity_name'] ?? '').toString().isNotEmpty)
                      _Badge(
                        label: 'Hoạt động: ${item.meta['activity_name']}',
                        color: AppColors.primary,
                      ),
                    if ((item.meta['appellation_name'] ?? '').toString().isNotEmpty)
                      _Badge(
                        label: 'Danh hiệu: ${item.meta['appellation_name']}',
                        color: const Color(0xFFF59E0B),
                      ),
                    if ((item.meta['points'] ?? '').toString().isNotEmpty)
                      _Badge(
                        label: 'Điểm: ${item.meta['points']}',
                        color: const Color(0xFF10B981),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
    return switch (type) {
      'drl_deduction' => 'TRỪ ĐIỂM DRL',
      'drl_award' => 'CỘNG ĐIỂM DRL',
      'appellation_approved' => 'DANH HIỆU ĐẠT',
      'appellation_rejected' => 'DANH HIỆU KHÔNG ĐẠT',
      'appellation_needs_revision' => 'CẦN BỔ SUNG HỒ SƠ',
      _ => 'THÔNG BÁO HỆ THỐNG',
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'drl_deduction' || 'appellation_rejected' => AppColors.danger,
      'drl_award' || 'appellation_approved' => const Color(0xFF059669),
      'appellation_needs_revision' => const Color(0xFFF59E0B),
      _ => AppColors.primary,
    };
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'drl_deduction' => Icons.remove_circle_outline_rounded,
      'drl_award' => Icons.add_circle_outline_rounded,
      'appellation_approved' => Icons.emoji_events_rounded,
      'appellation_rejected' => Icons.cancel_outlined,
      'appellation_needs_revision' => Icons.edit_note_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if ((list?.unreadCount ?? 0) > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _HeaderCard(unreadCount: list?.unreadCount ?? 0),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Chưa đọc'),
                    selected: _unreadOnly,
                    onSelected: (value) {
                      setState(() => _unreadOnly = value);
                      _load();
                    },
                  ),
                  DropdownMenu<String>(
                    width: 230,
                    initialSelection: _selectedType ?? '',
                    onSelected: (value) {
                      setState(() => _selectedType = value == '' ? null : value);
                      _load();
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: '', label: 'Tất cả loại'),
                      DropdownMenuEntry(value: 'drl_deduction', label: 'Trừ điểm DRL'),
                      DropdownMenuEntry(value: 'drl_award', label: 'Cộng điểm DRL'),
                      DropdownMenuEntry(value: 'appellation_approved', label: 'Danh hiệu đạt'),
                      DropdownMenuEntry(value: 'appellation_rejected', label: 'Danh hiệu không đạt'),
                      DropdownMenuEntry(value: 'appellation_needs_revision', label: 'Cần bổ sung hồ sơ'),
                      DropdownMenuEntry(value: 'system', label: 'Hệ thống'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _Message(message: _errorMessage!, isError: true)
              else if (list == null || list.items.isEmpty)
                const _Message(message: 'Bạn chưa có thông báo nào.', isError: false)
              else
                ...list.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      item: item,
                      onTap: () => _showDetail(item),
                      onMarkRead: () => _markRead(item),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo của bạn',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount > 0 ? '$unreadCount thông báo chưa đọc' : 'Không có thông báo chưa đọc',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  Color _colorForType(String type) {
    return switch (type) {
      'drl_deduction' || 'appellation_rejected' => AppColors.danger,
      'drl_award' || 'appellation_approved' => const Color(0xFF059669),
      'appellation_needs_revision' => const Color(0xFFF59E0B),
      _ => AppColors.primary,
    };
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'drl_deduction' => Icons.remove_circle_outline_rounded,
      'drl_award' => Icons.add_circle_outline_rounded,
      'appellation_approved' => Icons.emoji_events_rounded,
      'appellation_rejected' => Icons.cancel_outlined,
      'appellation_needs_revision' => Icons.edit_note_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(item.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? AppColors.card : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead ? AppColors.border : color.withValues(alpha: 0.25),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForType(item.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty ? 'Thông báo' : item.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          compactDate(item.createdAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Xem chi tiết >',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty || label == '-') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.notifications_none_rounded,
            color: isError ? AppColors.danger : AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? AppColors.danger : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
