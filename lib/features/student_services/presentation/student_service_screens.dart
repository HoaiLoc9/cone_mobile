// ignore_for_file: sort_child_properties_last, use_null_aware_elements

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/student_services_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late Future<List<StudentComplaint>> _future = widget.service.complaints();
  String _filter = 'all'; // 'all', 'pending', 'resolved'

  void _reload() => setState(() => _future = widget.service.complaints());

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Khiếu nại & Phản hồi',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo khiếu nại',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<StudentComplaint>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa tải được danh sách khiếu nại',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allItems = snapshot.data ?? [];
            final pendingCount = allItems.where((i) => i.response.isEmpty).length;
            final resolvedCount = allItems.where((i) => i.response.isNotEmpty).length;

            final filteredItems = allItems.where((item) {
              if (_filter == 'pending') return item.response.isEmpty;
              if (_filter == 'resolved') return item.response.isNotEmpty;
              return true;
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Thẻ hướng dẫn quy trình
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quyền lợi & Phúc khảo rèn luyện',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Nếu điểm hoạt động hoặc điểm rèn luyện chưa chính xác, bạn hãy gửi khiếu nại để Ban quản lý và Cán bộ xác minh giải quyết.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bộ lọc Tab
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Tất cả (${allItems.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Chờ phản hồi ($pendingCount)', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterPill('Đã giải quyết ($resolvedCount)', 'resolved'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              allItems.isEmpty ? 'Chưa có đơn khiếu nại nào' : 'Không có đơn trong danh mục này',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Nhấn nút "Tạo khiếu nại" bên dưới khi bạn cần phản ánh.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildComplaintCard(item),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(StudentComplaint item) {
    final hasResponse = item.response.isNotEmpty;
    final statusColor = hasResponse ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusBg = hasResponse ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final statusLabel = hasResponse ? 'ĐÃ PHẢN HỒI' : 'CHỜ XỬ LÝ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasResponse
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasResponse ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.report_problem_outlined, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text(
                    'Đơn phản ánh',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),

          if (hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text(
                        'Phản hồi từ Nhà trường / Cán bộ:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.response,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E3A8A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'Ban Quản lý đang tiếp nhận hồ sơ và sẽ phản hồi sớm nhất.',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }
}

class PermissionRequestsScreen extends StatefulWidget {
  const PermissionRequestsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<PermissionRequestsScreen> createState() =>
      _PermissionRequestsScreenState();
}

class _PermissionRequestsScreenState extends State<PermissionRequestsScreen> {
  late Future<List<PermissionRequestItem>> _future = widget.service
      .permissionRequests();

  void _reload() =>
      setState(() => _future = widget.service.permissionRequests());

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PermissionForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Giấy xin phép',
      subtitle: 'Vắng hoạt động, bù hoạt động, miễn hoạt động',
      action: IconButton(onPressed: _create, icon: const Icon(Icons.add)),
      child: FutureBuilder<List<PermissionRequestItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được giấy xin phép',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return AppStateView(
              icon: Icons.assignment_outlined,
              title: 'Chưa có giấy xin phép',
              message: 'Tạo giấy xin phép và đính kèm minh chứng nếu có.',
              actionLabel: 'Tạo giấy',
              onAction: _create,
            );
          }
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.title,
                  subtitle: '${item.typeLabel}\n${item.reason}',
                  status: item.statusLabel,
                  note: item.adminNote.isEmpty
                      ? 'Chưa có ghi chú xử lý.'
                      : item.adminNote,
                  icon: Icons.assignment_turned_in_outlined,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Tạo giấy'),
      ),
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<StudentDocument>> _future = widget.service.documents();

  void _reload() => setState(() => _future = widget.service.documents());

  Future<void> _upload() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DocumentForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Tài liệu hồ sơ',
      subtitle: 'Upload tài liệu và xem trạng thái duyệt',
      action: IconButton(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file),
      ),
      child: FutureBuilder<List<StudentDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được tài liệu',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return AppStateView(
              icon: Icons.folder_open_outlined,
              title: 'Chưa có tài liệu',
              message: 'Upload hồ sơ hoặc minh chứng để admin duyệt.',
              actionLabel: 'Upload',
              onAction: _upload,
            );
          }
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.title,
                  subtitle: item.type,
                  status: item.statusLabel,
                  note: item.adminNote.isEmpty
                      ? 'Chưa có ghi chú.'
                      : item.adminNote,
                  icon: Icons.description_outlined,
                  footer: item.fileUrl.isEmpty ? null : 'File: ${item.fileUrl}',
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}

class ProfileStatusScreen extends StatelessWidget {
  const ProfileStatusScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Trạng thái hồ sơ',
      subtitle: 'Tình trạng hồ sơ cá nhân và ghi chú admin',
      child: FutureBuilder<ProfileStatus>(
        future: service.profileStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được trạng thái hồ sơ',
              message: snapshot.error.toString(),
            );
          }
          final status = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              COneCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(status.statusLabel),
                    const SizedBox(height: 18),
                    const Text(
                      'Ghi chú xử lý',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.note.isEmpty
                          ? 'Chưa có ghi chú từ admin.'
                          : status.note,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CvScreen extends StatefulWidget {
  const CvScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  late Future<List<CvDocument>> _future = widget.service.cvs();

  void _reload() => setState(() => _future = widget.service.cvs());

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CvCreateForm(service: widget.service),
    );
    if (created == true) _reload();
  }

  Future<void> _edit(CvDocument cv) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CvEditorScreen(service: widget.service, cv: cv),
      ),
    );
    if (updated == true) _reload();
  }

  Future<void> _setDefault(CvDocument cv) async {
    await widget.service.setDefaultCv(cv.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'CV sinh viên',
      subtitle: 'Tạo, sửa, chọn CV mặc định',
      action: IconButton(onPressed: _create, icon: const Icon(Icons.add)),
      child: FutureBuilder<List<CvDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được CV',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              SectionHeader(
                title: 'Danh sách CV',
                subtitle:
                    'PDF có API `/mobile/cvs/{id}/pdf`; mở/tải file sẽ cần tích hợp lưu file ở phase sau.',
                actionLabel: 'Tạo CV',
                onAction: _create,
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const AppStateView(
                  icon: Icons.badge_outlined,
                  title: 'Chưa có CV',
                  message: 'Tạo CV từ template có sẵn của hệ thống.',
                )
              else
                for (final cv in items)
                  _InfoCard(
                    title: cv.name,
                    subtitle:
                        'Template: ${cv.templateId.isEmpty ? 'mặc định' : cv.templateId}',
                    status: cv.isDefault ? 'Mặc định' : 'Bản nháp',
                    note: 'Chạm để sửa nội dung CV.',
                    icon: Icons.badge_outlined,
                    onTap: () => _edit(cv),
                    trailing: cv.isDefault
                        ? null
                        : TextButton(
                            onPressed: () => _setDefault(cv),
                            child: const Text('Chọn mặc định'),
                          ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Tạo CV'),
      ),
    );
  }
}

class CvEditorScreen extends StatefulWidget {
  const CvEditorScreen({super.key, required this.service, required this.cv});

  final StudentServicesService service;
  final CvDocument cv;

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.cv.name,
  );
  late final TextEditingController _fullName = TextEditingController(
    text: widget.cv.personal['full_name']?.toString() ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.cv.personal['email']?.toString() ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.cv.personal['phone']?.toString() ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final personal = Map<String, dynamic>.from(widget.cv.personal)
        ..['full_name'] = _fullName.text.trim()
        ..['email'] = _email.text.trim()
        ..['phone'] = _phone.text.trim();
      await widget.service.updateCv(
        widget.cv.copyWith(name: _name.text.trim(), personal: personal),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Sửa CV',
      subtitle: widget.cv.name,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          COneCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Tên CV',
                  hint: 'CV thực tập',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _fullName,
                  label: 'Họ tên',
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'sv001@student.edu.vn',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone,
                  label: 'Điện thoại',
                  hint: '09...',
                  icon: Icons.phone_outlined,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Luu CV',
                  onPressed: _save,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivitySuggestionsScreen extends StatelessWidget {
  const ActivitySuggestionsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Gợi ý hoạt động',
      subtitle: 'Hoạt động phù hợp để cải thiện điểm rèn luyện',
      child: FutureBuilder<List<ActivitySuggestion>>(
        future: service.activitySuggestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được gợi ý',
              message: snapshot.error.toString(),
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.lightbulb_outline,
              title: 'Chưa có gợi ý',
              message:
                  'Hệ thống chưa tìm thấy hoạt động phù hợp tại thời điểm này.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.name,
                  subtitle: item.reasons.isEmpty
                      ? 'Phù hợp với hồ sơ hiện tại.'
                      : item.reasons.join('\n'),
                  status: '+${item.score} điểm',
                  note: 'Bạn có thể vào mục Hoạt động để xem và đăng ký.',
                  icon: Icons.lightbulb_outline,
                ),
            ],
          );
        },
      ),
    );
  }
}

class SignatureRequestsScreen extends StatefulWidget {
  const SignatureRequestsScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<SignatureRequestsScreen> createState() =>
      _SignatureRequestsScreenState();
}

class _SignatureRequestsScreenState extends State<SignatureRequestsScreen> {
  late Future<List<SignatureRequestItem>> _future = widget.service
      .signatureRequests();

  void _reload() =>
      setState(() => _future = widget.service.signatureRequests());

  Future<void> _open(SignatureRequestItem item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SignatureRequestDetailScreen(service: widget.service, item: item),
      ),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Chữ ký số',
      subtitle: 'Hồ sơ cần ký và canvas ký tên',
      child: FutureBuilder<List<SignatureRequestItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được hồ sơ cần ký',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.draw_outlined,
              title: 'Chưa có hồ sơ cần ký',
              message:
                  'Khi admin yêu cầu ký hồ sơ, danh sách sẽ hiển thị tại đây.',
            );
          }
          return _RefreshList(
            onRefresh: () async => _reload(),
            children: [
              for (final item in items)
                _InfoCard(
                  title: item.title.isEmpty ? 'Hồ sơ cần ký' : item.title,
                  subtitle: item.description,
                  status: item.statusLabel,
                  note: item.mayBeSigned
                      ? 'Có thể ký ngay trên điện thoại.'
                      : 'Hồ sơ chưa mở để ký hoặc đã xử lý.',
                  icon: Icons.draw_outlined,
                  footer: item.documentOriginalName.isEmpty
                      ? null
                      : 'Tệp: ${item.documentOriginalName}',
                  onTap: () => _open(item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class SignatureRequestDetailScreen extends StatefulWidget {
  const SignatureRequestDetailScreen({
    super.key,
    required this.service,
    required this.item,
  });

  final StudentServicesService service;
  final SignatureRequestItem item;

  @override
  State<SignatureRequestDetailScreen> createState() =>
      _SignatureRequestDetailScreenState();
}

class _SignatureRequestDetailScreenState
    extends State<SignatureRequestDetailScreen> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _acknowledgement = false;
  bool _saving = false;
  String? _error;

  void _clear() => setState(_points.clear);

  Future<String?> _signaturePngDataUrl() async {
    if (_points.whereType<Offset>().isEmpty) return null;
    final boundary =
        _signatureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.5);
    final bytes = await image?.toByteData(format: ui.ImageByteFormat.png);
    final data = bytes?.buffer.asUint8List();
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data)}';
  }

  Future<void> _sign() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final signatureData = await _signaturePngDataUrl();
      if (signatureData == null) {
        setState(
          () => _error = 'Vui lòng ký trên vùng trắng trước khi xác nhận.',
        );
        return;
      }
      await widget.service.signSignatureRequest(
        id: widget.item.id,
        signatureData: signatureData,
        acknowledgement: _acknowledgement,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return _ServiceScaffold(
      title: 'Ký hồ sơ',
      subtitle: item.title,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _InfoCard(
            title: item.title.isEmpty ? 'Hồ sơ cần ký' : item.title,
            subtitle: item.description,
            status: item.statusLabel,
            note: item.acknowledgementText.isEmpty
                ? 'Vui lòng đọc kỹ hồ sơ trước khi ký.'
                : item.acknowledgementText,
            icon: Icons.assignment_outlined,
            footer: item.documentUrl.isEmpty
                ? null
                : 'Link hồ sơ: ${item.documentUrl}',
          ),
          const SizedBox(height: 12),
          COneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ký tên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                RepaintBoundary(
                  key: _signatureKey,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final box =
                          _signatureKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      final offset = box?.globalToLocal(details.globalPosition);
                      if (offset != null) setState(() => _points.add(offset));
                    },
                    onPanUpdate: (details) {
                      final box =
                          _signatureKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      final offset = box?.globalToLocal(details.globalPosition);
                      if (offset != null) setState(() => _points.add(offset));
                    },
                    onPanEnd: (_) => setState(() => _points.add(null)),
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: _acknowledgement,
                        onChanged: item.mayBeSigned
                            ? (value) => setState(
                                () => _acknowledgement = value ?? false,
                              )
                            : null,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Tôi đã đọc và đồng ý với nội dung hồ sơ.',
                        ),
                      ),
                    ),
                    TextButton(onPressed: _clear, child: const Text('Xóa ký')),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Ký xác nhận',
                  onPressed: item.mayBeSigned ? _sign : null,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  const _ComplaintForm({required this.service});

  final StudentServicesService service;

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final content = _content.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tiêu đề khiếu nại.');
      return;
    }
    if (content.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung giải trình chi tiết.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.createComplaint(
        title: title,
        content: content,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Gửi đơn khiếu nại rèn luyện',
      error: _error,
      children: [
        AppTextField(
          controller: _title,
          label: 'Tiêu đề khiếu nại',
          hint: 'Ví dụ: Phúc khảo điểm hoạt động Chào tân sinh viên',
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _content,
          label: 'Nội dung chi tiết',
          hint: 'Trình bày rõ lý do, thời gian tham gia và đề xuất của bạn...',
          icon: Icons.notes_rounded,
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Gửi khiếu nại ngay', onPressed: _submit, isLoading: _saving),
      ],
    );
  }
}

class _PermissionForm extends StatefulWidget {
  const _PermissionForm({required this.service});

  final StudentServicesService service;

  @override
  State<_PermissionForm> createState() => _PermissionFormState();
}

class _PermissionFormState extends State<_PermissionForm> {
  final _title = TextEditingController();
  final _reason = TextEditingController();
  String _type = 'absence';
  FilePayload? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(() => _file = FilePayload(name: compressed.name, bytes: compressed.bytes));
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.service.createPermissionRequest(
        type: _type,
        title: _title.text.trim(),
        reason: _reason.text.trim(),
        evidence: _file,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Tạo giấy xin phép',
      error: _error,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Loại giấy'),
          items: const [
            DropdownMenuItem(value: 'absence', child: Text('Vắng hoạt động')),
            DropdownMenuItem(value: 'makeup', child: Text('Bù hoạt động')),
            DropdownMenuItem(value: 'exemption', child: Text('Miễn hoạt động')),
          ],
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _title,
          label: 'Tiêu đề',
          hint: 'Xin phép vắng hoạt động...',
          icon: Icons.title,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _reason,
          label: 'Lý do',
          hint: 'Nêu lý do và thời gian liên quan',
          icon: Icons.notes_outlined,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: Text(_file == null ? 'Chọn minh chứng' : _file!.name),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Gửi giấy',
          onPressed: _submit,
          isLoading: _saving,
        ),
      ],
    );
  }
}

class _DocumentForm extends StatefulWidget {
  const _DocumentForm({required this.service});

  final StudentServicesService service;

  @override
  State<_DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<_DocumentForm> {
  final _title = TextEditingController();
  final _type = TextEditingController(text: 'profile');
  FilePayload? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final compressed = await ImageCompressor.compressImage(
      fileName: file!.name,
      bytes: file.bytes!,
    );
    setState(() => _file = FilePayload(name: compressed.name, bytes: compressed.bytes));
  }

  Future<void> _submit() async {
    if (_file == null) {
      setState(() => _error = 'Vui lòng chọn tài liệu cần upload.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.uploadDocument(
        title: _title.text.trim(),
        type: _type.text.trim(),
        file: _file!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Upload tài liệu',
      error: _error,
      children: [
        AppTextField(
          controller: _title,
          label: 'Tên tài liệu',
          hint: 'CMND/CCCD, giấy xác nhận...',
          icon: Icons.title,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _type,
          label: 'Loại tài liệu',
          hint: 'profile/evidence/other',
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: Text(_file == null ? 'Chọn file' : _file!.name),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Upload', onPressed: _submit, isLoading: _saving),
      ],
    );
  }
}

class _CvCreateForm extends StatefulWidget {
  const _CvCreateForm({required this.service});

  final StudentServicesService service;

  @override
  State<_CvCreateForm> createState() => _CvCreateFormState();
}

class _CvCreateFormState extends State<_CvCreateForm> {
  final _name = TextEditingController(text: 'CV sinh viên');
  late final Future<List<CvTemplate>> _templates = widget.service.cvTemplates();
  String? _templateId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final templateId = _templateId;
    if (templateId == null || templateId.isEmpty) {
      setState(() => _error = 'Vui lòng chọn template CV.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createCv(
        name: _name.text.trim(),
        templateId: templateId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : error.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: 'Tạo CV theo template',
      error: _error,
      children: [
        AppTextField(
          controller: _name,
          label: 'Tên CV',
          hint: 'CV ứng tuyển CLB...',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<CvTemplate>>(
          future: _templates,
          builder: (context, snapshot) {
            final templates = snapshot.data ?? const <CvTemplate>[];
            if (_templateId == null && templates.isNotEmpty) {
              _templateId = templates.first.id;
            }
            return DropdownButtonFormField<String>(
              initialValue: _templateId,
              decoration: const InputDecoration(labelText: 'Template'),
              items: [
                for (final template in templates)
                  DropdownMenuItem(
                    value: template.id,
                    child: Text(template.name),
                  ),
              ],
              onChanged: (value) => setState(() => _templateId = value),
            );
          },
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Tạo CV', onPressed: _submit, isLoading: _saving),
      ],
    );
  }
}

class _ServiceScaffold extends StatelessWidget {
  const _ServiceScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [if (action != null) action!],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: children,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.note,
    required this.icon,
    this.footer,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String status;
  final String note;
  final IconData icon;
  final String? footer;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: COneCard(
        onTap: onTap,
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing!),
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

class _FormSheet extends StatelessWidget {
  const _FormSheet({required this.title, required this.children, this.error});

  final String title;
  final List<Widget> children;
  final String? error;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            ...children,
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBlue
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.2;
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}



