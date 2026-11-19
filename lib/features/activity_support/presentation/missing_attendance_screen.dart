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

class _MissingAttendanceScreenState extends State<MissingAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  MissingAttendanceData? _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        () => _errorMessage = 'Không tải được dữ liệu minh chứng.',
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
      useRootNavigator: true,
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
    final eligibleCount = data?.eligible.length ?? 0;
    final requestCount = data?.requests.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Minh chứng rèn luyện',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.adaptiveTextPrimary, fontSize: 18),
        ),
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.appBarBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.adaptiveTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Cần nộp'),
                      if (eligibleCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$eligibleCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Lịch sử đã gửi'),
                      if (requestCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$requestCount',
                            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Cần nộp minh chứng
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          children: [
                            _buildInfoGuideCard(),
                            const SizedBox(height: 16),
                            if ((data?.eligible ?? const []).isEmpty)
                              _buildEmptyTab(
                                icon: Icons.check_circle_outline_rounded,
                                title: 'Không có hoạt động cần bổ sung',
                                message: 'Tuyệt vời! Bạn không bị thiếu lượt quét mã check-in hoặc check-out ở hoạt động nào.',
                              )
                            else
                              ...(data?.eligible ?? const []).map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildEligibleItemCard(item: item, onSubmit: () => _openSubmit(item)),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Tab 2: Lịch sử đã gửi minh chứng
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          children: [
                            if ((data?.requests ?? const []).isEmpty)
                              _buildEmptyTab(
                                icon: Icons.history_rounded,
                                title: 'Chưa có yêu cầu nào',
                                message: 'Lịch sử các yêu cầu nộp minh chứng và phản hồi duyệt từ Nhà trường sẽ xuất hiện ở đây.',
                              )
                            else
                              ...(data?.requests ?? const []).map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRequestItemCard(item: item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInfoGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.camera_alt_outlined, color: Colors.amberAccent, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy định nộp minh chứng',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Khi tham gia hoạt động nhưng máy lỗi không quét được check-in/out, bạn hãy chụp ảnh tại sự kiện để gửi xét duyệt cộng điểm bù.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibleItemCard({
    required MissingAttendanceEligible item,
    required VoidCallback onSubmit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.missingTypeLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text(
                    'Chưa hoàn tất',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.adaptiveTextPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppColors.adaptiveTextSecondary),
              const SizedBox(width: 5),
              Text(
                '${compactDate(item.timeStart)} - ${compactDate(item.timeStop)}',
                style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onSubmit,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Nộp ảnh minh chứng', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItemCard({required MissingAttendanceRequest item}) {
    final (statusColor, statusBg, statusIcon) = switch (item.status) {
      'approved' => (const Color(0xFF10B981), const Color(0xFFD1FAE5), Icons.check_circle_rounded),
      'rejected' => (const Color(0xFFEF4444), const Color(0xFFFEE2E2), Icons.cancel_rounded),
      _ => (const Color(0xFFF59E0B), const Color(0xFFFEF3C7), Icons.hourglass_top_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.missingTypeLabel,
                style: TextStyle(fontSize: 11.5, color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.activityName,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.adaptiveTextPrimary),
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.reason,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.evidenceName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attachment_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.evidenceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
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
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;

    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(
      () => _upload = SupportUpload(name: compressed.name, bytes: compressed.bytes),
    );
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do nộp minh chứng.');
      return;
    }
    if (_upload == null) {
      setState(() => _errorMessage = 'Vui lòng tải lên ảnh minh chứng tại sự kiện.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.service.submitMissingAttendance(
        activityId: widget.item.id,
        reason: reason,
        evidence: _upload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nộp minh chứng thành công! Ban quản lý sẽ xem xét.')),
      );
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Không gửi được minh chứng. Kiểm tra kết nối mạng.',
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
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
              Text(
                'Nộp minh chứng điểm danh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.adaptiveTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.name,
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'LÝ DO CHƯA ĐIỂM DANH ĐƯỢC',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.adaptiveTextSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: AppColors.adaptiveTextPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: Máy quét mã báo lỗi, điện thoại hết pin lúc check-out...',
                  filled: true,
                  fillColor: AppColors.cardSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.adaptiveBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ẢNH CHỨNG MINH THAM GIA HOẠT ĐỘNG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              if (_upload != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_rounded, color: Color(0xFF16A34A)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _upload!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _upload = null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: _pickFile,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(_upload == null ? 'Chọn ảnh minh chứng từ máy' : 'Đổi ảnh khác'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Gửi minh chứng ngay',
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
