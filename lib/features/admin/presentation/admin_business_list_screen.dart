import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/admin_service.dart';

enum AdminBusinessAction {
  none,
  resolveComplaint,
  approveRejectPermission,
  approveRejectDocument,
  updateProfileStatus,
  sendNotification,
  createBackup,
  gvcnApproveRejectPermission,
}

class AdminBusinessListScreen extends StatefulWidget {
  const AdminBusinessListScreen({
    super.key,
    required this.service,
    required this.title,
    required this.path,
    required this.icon,
    this.action = AdminBusinessAction.none,
  });

  final AdminService service;
  final String title;
  final String path;
  final IconData icon;
  final AdminBusinessAction action;

  @override
  State<AdminBusinessListScreen> createState() =>
      _AdminBusinessListScreenState();
}

class _AdminBusinessListScreenState extends State<AdminBusinessListScreen> {
  late Future<List<AdminBusinessItem>> _future = widget.service.businessItems(
    widget.path,
  );
  bool _busy = false;

  void _reload() =>
      setState(() => _future = widget.service.businessItems(widget.path));

  Future<void> _runAction(AdminBusinessItem item, bool positive) async {
    final note = await _noteDialog(
      positive ? 'Ghi chú xử lý' : 'Lý do từ chối / phản hồi',
      positive ? 'Đồng ý xử lý trên mobile.' : 'Nhập lý do để sinh viên biết.',
    );
    if (note == null) return;
    setState(() => _busy = true);
    try {
      switch (widget.action) {
        case AdminBusinessAction.resolveComplaint:
          await widget.service.resolveComplaint(
            id: item.id,
            status: positive ? 'resolved' : 'received',
            response: note,
          );
          break;
        case AdminBusinessAction.approveRejectPermission:
          positive
              ? await widget.service.approvePermission(item.id, note: note)
              : await widget.service.rejectPermission(item.id, note: note);
          break;
        case AdminBusinessAction.approveRejectDocument:
          positive
              ? await widget.service.approveDocument(item.id, note: note)
              : await widget.service.rejectDocument(item.id, note: note);
          break;
        case AdminBusinessAction.updateProfileStatus:
          await widget.service.updateProfileStatus(
            userId: item.studentId,
            status: positive ? 'approved' : 'need_update',
            note: note,
          );
          break;
        case AdminBusinessAction.gvcnApproveRejectPermission:
          positive
              ? await widget.service.gvcnApprovePermission(item.id, note: note)
              : await widget.service.gvcnRejectPermission(item.id, note: note);
          break;
        case AdminBusinessAction.none:
        case AdminBusinessAction.sendNotification:
        case AdminBusinessAction.createBackup:
          break;
      }
      _reload();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createNotification() async {
    final result = await showModalBottomSheet<_NotificationDraft>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _NotificationSheet(),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await widget.service.sendNotification(
        title: result.title,
        message: result.message,
      );
      _reload();
    } catch (error) {
      _showError(error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      await widget.service.createBackup();
      _reload();
    } catch (error) {
      _showError(error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _noteDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canCreateNotification =
        widget.action == AdminBusinessAction.sendNotification;
    final canCreateBackup = widget.action == AdminBusinessAction.createBackup;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (canCreateNotification)
            IconButton(
              onPressed: _busy ? null : _createNotification,
              icon: const Icon(Icons.add),
            ),
          if (canCreateBackup)
            IconButton(
              onPressed: _busy ? null : _createBackup,
              icon: const Icon(Icons.backup_outlined),
            ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<AdminBusinessItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được dữ liệu',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return AppStateView(
              icon: widget.icon,
              title: 'Chưa có dữ liệu',
              message: 'API đã kết nối nhưng hiện chưa có bản ghi phù hợp.',
              actionLabel: 'Tải lại',
              onAction: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              itemBuilder: (context, index) => _BusinessCard(
                item: items[index],
                icon: widget.icon,
                busy: _busy,
                action: widget.action,
                onPositive: () => _runAction(items[index], true),
                onNegative: () => _runAction(items[index], false),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.item,
    required this.icon,
    required this.busy,
    required this.action,
    required this.onPositive,
    required this.onNegative,
  });

  final AdminBusinessItem item;
  final IconData icon;
  final bool busy;
  final AdminBusinessAction action;
  final VoidCallback onPositive;
  final VoidCallback onNegative;

  @override
  Widget build(BuildContext context) {
    final hasApproval = {
      AdminBusinessAction.resolveComplaint,
      AdminBusinessAction.approveRejectPermission,
      AdminBusinessAction.approveRejectDocument,
      AdminBusinessAction.updateProfileStatus,
      AdminBusinessAction.gvcnApproveRejectPermission,
    }.contains(action);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: COneCard(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? 'Bản ghi mobile' : item.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if (item.studentName.isNotEmpty)
                        Text(
                          '${item.studentCode} • ${item.studentName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusPill(item.status),
              ],
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.note,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (hasApproval) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onNegative,
                      child: Text(
                        action == AdminBusinessAction.resolveComplaint
                            ? 'Tiếp nhận'
                            : 'Từ chối',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onPositive,
                      child: Text(
                        action == AdminBusinessAction.resolveComplaint
                            ? 'Hoàn tất'
                            : 'Duyệt',
                      ),
                    ),
                  ),
                ],
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

class _NotificationDraft {
  const _NotificationDraft({required this.title, required this.message});

  final String title;
  final String message;
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  final _title = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _title,
              label: 'Tiêu đề',
              hint: 'Thông báo mới',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _message,
              label: 'Nội dung',
              hint: 'Nhập nội dung thông báo',
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Gửi thông báo',
              onPressed: () => Navigator.of(context).pop(
                _NotificationDraft(
                  title: _title.text.trim(),
                  message: _message.text.trim(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
