import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../data/activity_support_models.dart';
import '../data/activity_support_service.dart';

class MissingAttendanceScreen extends StatefulWidget {
  const MissingAttendanceScreen({super.key, required this.service});

  final ActivitySupportService service;

  @override
  State<MissingAttendanceScreen> createState() =>
      _MissingAttendanceScreenState();
}

class _MissingAttendanceScreenState extends State<MissingAttendanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  MissingAttendanceData? _data;

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
      final data = await widget.service.fetchMissingAttendance();
      setState(() => _data = data);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Không tải được dữ liệu bổ sung điểm danh.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSubmit(MissingAttendanceEligible item) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitSheet(service: widget.service, item: item),
    );
    if (ok == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bổ sung điểm danh',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _Message(message: _errorMessage!, isError: true)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    const _HeaderCard(),
                    const SizedBox(height: 18),
                    const Text(
                      'Có thể gửi yêu cầu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((data?.eligible ?? const []).isEmpty)
                      const _EmptyCard(
                        message: 'Chưa có hoạt động thiếu đúng một lượt quét.',
                      )
                    else
                      ...(data?.eligible ?? const []).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EligibleCard(
                            item: item,
                            onSubmit: () => _openSubmit(item),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Yêu cầu đã gửi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((data?.requests ?? const []).isEmpty)
                      const _EmptyCard(
                        message: 'Bạn chưa gửi yêu cầu bổ sung nào.',
                      )
                    else
                      ...(data?.requests ?? const []).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(item: item),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SubmitSheet extends StatefulWidget {
  const _SubmitSheet({required this.service, required this.item});

  final ActivitySupportService service;
  final MissingAttendanceEligible item;

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final _reasonController = TextEditingController();
  SupportUpload? _upload;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
      ],
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) {
      return;
    }
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(
      () => _upload = SupportUpload(name: compressed.name, bytes: compressed.bytes),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.service.submitMissingAttendance(
        activityId: widget.item.id,
        reason: _reasonController.text.trim(),
        evidence: _upload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu bổ sung điểm danh.')),
      );
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Không gửi được yêu cầu. Kiểm tra kết nối API.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.missingTypeLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Lý do bổ sung',
                  hintText: 'Nhập lý do tối thiểu 10 ký tự...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _upload == null ? 'Chọn minh chứng' : _upload!.name,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Gửi yêu cầu',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          Icon(Icons.fact_check_outlined, color: Colors.white, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Gửi yêu cầu khi bạn chỉ thiếu check-in hoặc check-out, kèm minh chứng để admin xét duyệt.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibleCard extends StatelessWidget {
  const _EligibleCard({required this.item, required this.onSubmit});

  final MissingAttendanceEligible item;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${compactDate(item.timeStart)} - ${compactDate(item.timeStop)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Badge(
                label: item.missingTypeLabel,
                color: const Color(0xFFF59E0B),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onSubmit,
                child: const Text('Gửi bổ sung'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final MissingAttendanceRequest item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      'approved' => const Color(0xFF059669),
      'rejected' => AppColors.danger,
      _ => const Color(0xFFF59E0B),
    };
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.activityName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: item.statusLabel, color: color),
              _Badge(label: item.missingTypeLabel, color: AppColors.primary),
              if (item.evidenceName.isNotEmpty)
                _Badge(
                  label: item.evidenceName,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 130),
        Icon(
          isError ? Icons.error_outline : Icons.inbox_outlined,
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
    );
  }
}
