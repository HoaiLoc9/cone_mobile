import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activity_support/data/activity_support_models.dart';
import '../../activity_support/data/activity_support_service.dart';
import 'activity_helpers.dart';

class MissingCheckoutSheet extends StatefulWidget {
  const MissingCheckoutSheet({
    super.key,
    required this.service,
    required this.activityId,
    required this.activityName,
    this.timeStop,
    this.location,
    this.points,
  });

  final ActivitySupportService service;
  final String activityId;
  final String activityName;
  final DateTime? timeStop;
  final String? location;
  final double? points;

  static Future<bool?> show(
    BuildContext context, {
    required ActivitySupportService service,
    required String activityId,
    required String activityName,
    DateTime? timeStop,
    String? location,
    double? points,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MissingCheckoutSheet(
        service: service,
        activityId: activityId,
        activityName: activityName,
        timeStop: timeStop,
        location: location,
        points: points,
      ),
    );
  }

  @override
  State<MissingCheckoutSheet> createState() => _MissingCheckoutSheetState();
}

class _MissingCheckoutSheetState extends State<MissingCheckoutSheet> {
  final TextEditingController _reasonController = TextEditingController();
  SupportUpload? _upload;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isExpired {
    if (widget.timeStop == null) return false;
    final deadline = widget.timeStop!.add(const Duration(days: 3));
    return DateTime.now().isAfter(deadline);
  }

  DateTime? get _deadline => widget.timeStop?.add(const Duration(days: 3));

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
      );
      final file = result?.files.firstOrNull;
      if (file?.bytes == null) return;

      final compressed = await ImageCompressor.compressImage(
        fileName: file!.name,
        bytes: file.bytes!,
      );
      setState(() {
        _upload = SupportUpload(name: compressed.name, bytes: compressed.bytes);
        _errorMessage = null;
      });
    } catch (_) {
      setState(() => _errorMessage = 'Không thể chọn ảnh từ thiết bị.');
    }
  }

  Future<void> _submit() async {
    if (_isExpired) {
      setState(() => _errorMessage = 'Đã quá thời hạn 3 ngày để bổ sung check-out cho hoạt động này.');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.length < 10) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do cụ thể (tối thiểu 10 ký tự).');
      return;
    }
    if (_upload == null) {
      setState(() => _errorMessage = 'Vui lòng đính kèm ảnh minh chứng tham gia sự kiện.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.service.submitMissingAttendance(
        activityId: widget.activityId,
        reason: reason,
        evidence: _upload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không gửi được yêu cầu bổ sung. Vui lòng thử lại.');
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
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bổ sung điểm danh Check-out',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gửi yêu cầu kèm minh chứng cho QTV duyệt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adaptiveTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.adaptiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ĐÃ KẾT THÚC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.timeStop != null)
                            Expanded(
                              child: Text(
                                'Kết thúc: ${formatDateTime(widget.timeStop)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.adaptiveTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.activityName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      if (widget.location != null && widget.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 14, color: AppColors.adaptiveTextSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_deadline != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                              size: 14,
                              color: _isExpired ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _isExpired
                                    ? 'Đã hết hạn nộp (hạn chót: ${formatDateTime(_deadline)})'
                                    : 'Hạn chót bổ sung: trước ${formatDateTime(_deadline)} (trong vòng 3 ngày)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isExpired ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.points != null && widget.points! > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Trước khi được duyệt hoặc bị từ chối: Tạm tính 50% (+${(widget.points! / 2).toStringAsFixed(widget.points! % 2 == 0 ? 0 : 1)} ĐRL). Khi được duyệt sẽ cộng đủ +${widget.points!.toStringAsFixed(widget.points! % 1 == 0 ? 0 : 1)} ĐRL.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'LÝ DO CHƯA CHECK-OUT ĐƯỢC *',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: AppColors.adaptiveTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'VD: Máy quét báo bận, điện thoại hết pin lúc về, rời hội trường gấp...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.adaptiveTextSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.cardSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.adaptiveBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ẢNH MINH CHỨNG THAM GIA HOẠT ĐỘNG *',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (_upload != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _upload!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _upload = null),
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF15803D)),
                          tooltip: 'Gỡ ảnh',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.adaptiveTextPrimary,
                    side: BorderSide(color: AppColors.adaptiveBorder, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _pickFile,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 20, color: Color(0xFFD97706)),
                  label: Text(
                    _upload == null ? 'Chọn ảnh minh chứng từ máy' : 'Đổi ảnh khác',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isExpired
                      ? 'Đã hết hạn bổ sung check-out'
                      : 'Gửi yêu cầu cho Quản trị viên duyệt',
                  icon: _isExpired ? Icons.timer_off_outlined : Icons.send_rounded,
                  backgroundColor: _isExpired ? const Color(0xFF94A3B8) : const Color(0xFFD97706),
                  isLoading: _isSubmitting,
                  onPressed: _isExpired ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
