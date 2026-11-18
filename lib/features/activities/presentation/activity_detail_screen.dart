import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activity_support/data/activity_support_service.dart';
import '../../activity_support/presentation/certificate_screen.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';
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
          const Text(
            'Mô tả',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activity.description.trim().isEmpty
                ? 'Chưa có mô tả chi tiết.'
                : activity.description.trim(),
            style: const TextStyle(
              color: AppColors.textSecondary,
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
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
        color: AppColors.card,
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
