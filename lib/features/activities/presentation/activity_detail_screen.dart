import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activity_support/data/activity_support_service.dart';
import '../../activity_support/presentation/certificate_screen.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';
import 'activity_collaborator_panel.dart';
import 'activity_helpers.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.service,
    required this.activityId,
  });

  final ActivityService service;
  final String activityId;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  ActivityItem? _activity;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

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
      final activity = await widget.service.fetchActivity(widget.activityId);
      setState(() => _activity = activity);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được chi tiết hoạt động.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleRegistration() async {
    final activity = _activity;
    if (activity == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final updated = activity.isRegistered
          ? await widget.service.cancel(activity.id)
          : await widget.service.register(activity.id);
      setState(() => _activity = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isRegistered
                  ? 'Đăng ký hoạt động thành công.'
                  : 'Đã hủy đăng ký hoạt động.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể cập nhật đăng ký.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openCertificate() {
    final activity = _activity;
    if (activity == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificateScreen(
          service: ActivitySupportService(token: widget.service.token),
          activityId: activity.id,
          activityName: activity.name,
        ),
      ),
    );
  }

  String _formatIsoForCalendar(DateTime? dt) {
    final valid = dt?.toUtc() ?? DateTime.now().toUtc();
    return '${valid.year.toString().padLeft(4, '0')}'
        '${valid.month.toString().padLeft(2, '0')}'
        '${valid.day.toString().padLeft(2, '0')}T'
        '${valid.hour.toString().padLeft(2, '0')}'
        '${valid.minute.toString().padLeft(2, '0')}'
        '${valid.second.toString().padLeft(2, '0')}Z';
  }

  void _showAddToCalendarModal(ActivityItem act) {
    final startIso = _formatIsoForCalendar(act.timeStart);
    final endIso = _formatIsoForCalendar(act.timeStop ?? act.timeStart);
    final titleEnc = Uri.encodeComponent(act.name);
    final descEnc = Uri.encodeComponent(
      'Hoạt động rèn luyện: ${act.name}\nĐịa điểm: ${act.location}\nChi tiết: ${act.description}',
    );
    final locEnc = Uri.encodeComponent(act.location);
    final googleCalUrl =
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$titleEnc&dates=$startIso/$endIso&details=$descEnc&location=$locEnc';

    final eventSummary =
        '📅 Hoạt động: ${act.name}\n'
        '⏰ Bắt đầu: ${formatDateTime(act.timeStart)}\n'
        '🏁 Kết thúc: ${formatDateTime(act.timeStop)}\n'
        '📍 Địa điểm: ${act.location.isNotEmpty ? act.location : "Chưa cập nhật"}\n'
        '📝 Mô tả: ${act.description}';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.adaptiveBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2563EB),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đồng bộ Lịch sự kiện',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhắc nhở tham gia hoạt động rèn luyện',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.adaptiveBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        formatDateTime(act.timeStart),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                Navigator.of(ctx).pop();
                var opened = false;
                try {
                  opened = await launchUrl(
                    Uri.parse(googleCalUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}
                if (!opened) {
                  await Clipboard.setData(ClipboardData(text: googleCalUrl));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Không mở được Google Calendar, đã sao chép link vào bộ nhớ tạm.'),
                      backgroundColor: Color(0xFF2563EB),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text(
                'Mở Google Calendar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adaptiveTextPrimary,
                side: BorderSide(color: AppColors.adaptiveBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                await Clipboard.setData(ClipboardData(text: eventSummary));
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép toàn bộ thông tin hoạt động vào Bộ nhớ tạm! 📋'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Sao chép tóm tắt & Lịch trình hoạt động'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_activity);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.adaptiveBackground,
          surfaceTintColor: AppColors.adaptiveBackground,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_activity),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Chi tiết hoạt động',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : activity == null
              ? _ErrorMessage(
                  message: _errorMessage ?? 'Không tìm thấy hoạt động.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(activity: activity),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBox(message: _errorMessage!),
                      ],
                      const SizedBox(height: 18),
                      ActivityCollaboratorPanel(
                        activity: activity,
                        service: widget.service,
                      ),
                      _InfoSection(activity: activity),
                      const SizedBox(height: 18),
                      _DescriptionSection(activity: activity),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: activity.isRegistered
                            ? 'Hủy đăng ký'
                            : 'Đăng ký hoạt động',
                        isLoading: _isSubmitting,
                        onPressed: activity.isRegistered
                            ? (activity.canCancel ? _toggleRegistration : null)
                            : (activity.canRegister
                                  ? _toggleRegistration
                                  : null),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openCertificate,
                          icon: const Icon(Icons.card_membership_rounded),
                          label: const Text('Xem giấy chứng nhận'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: Color(0xFF93C5FD), width: 1.2),
                            backgroundColor: AppColors.isDark
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.2)
                                : const Color(0xFFEFF6FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showAddToCalendarModal(activity),
                          icon: const Icon(Icons.event_available_rounded, size: 20),
                          label: const Text(
                            'Thêm vào Lịch điện thoại (Google Calendar)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              activity.statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            activity.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            activity.location.isEmpty
                ? 'Chưa cập nhật địa điểm'
                : activity.location,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.schedule,
            label: 'Bắt đầu',
            value: formatDateTime(activity.timeStart),
          ),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Kết thúc',
            value: formatDateTime(activity.timeStop),
          ),
          _InfoRow(
            icon: Icons.event_note_outlined,
            label: 'Hạn đăng ký',
            value: compactDate(activity.registrationEnd),
          ),
          _InfoRow(
            icon: Icons.stars_outlined,
            label: 'Điểm DRL',
            value: activity.points.toStringAsFixed(
              activity.points.truncateToDouble() == activity.points ? 0 : 1,
            ),
          ),
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'Số lượng',
            value: activity.maxRegistrations > 0
                ? '${activity.registeredCount}/${activity.maxRegistrations}'
                : '${activity.registeredCount} đăng ký',
          ),
          _InfoRow(
            icon: Icons.how_to_reg_outlined,
            label: 'Trạng thái đăng ký',
            value: activity.registrationStatusLabel,
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activity.description.trim().isEmpty
                ? 'Chưa có mô tả chi tiết.'
                : activity.description.trim(),
            style: TextStyle(
              color: AppColors.adaptiveTextSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
