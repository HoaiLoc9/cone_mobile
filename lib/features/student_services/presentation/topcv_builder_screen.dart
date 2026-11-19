// ignore_for_file: use_null_aware_elements

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_service.dart';
import '../data/student_services_service.dart';

class TopCvBuilderScreen extends StatefulWidget {
  const TopCvBuilderScreen({super.key, required this.service});

  final StudentServicesService service;

  @override
  State<TopCvBuilderScreen> createState() => _TopCvBuilderScreenState();
}

class _TopCvBuilderScreenState extends State<TopCvBuilderScreen> {
  late Future<List<CvDocument>> _future = widget.service.cvs();

  void _reload() => setState(() => _future = widget.service.cvs());

  Future<void> _createNewCv() async {
    final created = await showModalBottomSheet<CvDocument>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopCvCreateSheet(service: widget.service),
    );
    if (created != null && mounted) {
      await _openEditor(created, autoFillIfEmpty: true);
    }
  }

  Future<void> _openEditor(CvDocument cv, {bool autoFillIfEmpty = false}) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TopCvEditorScreen(
          service: widget.service,
          cv: cv,
          autoFillOnInit: autoFillIfEmpty,
        ),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  Future<void> _setDefault(CvDocument cv) async {
    try {
      await widget.service.setDefaultCv(cv.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đặt làm CV mặc định!'),
          backgroundColor: AppColors.primary,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _duplicate(CvDocument cv) async {
    try {
      await widget.service.duplicateCv(cv.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nhân bản CV thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _delete(CvDocument cv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa CV?'),
        content: Text('Bạn có chắc chắn muốn xóa "${cv.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.service.deleteCv(cv.id);
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa CV: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  int _calculateCompleteness(CvDocument cv) {
    int score = 0;
    final p = cv.personal;
    if ((p['full_name']?.toString().trim() ?? '').isNotEmpty) score += 15;
    if ((p['email']?.toString().trim() ?? '').isNotEmpty) score += 10;
    if ((p['phone']?.toString().trim() ?? '').isNotEmpty) score += 10;
    if ((p['job_position']?.toString().trim() ?? '').isNotEmpty) score += 10;

    for (final raw in cv.sections) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString() ?? '';
      final content = raw['content']?.toString().trim() ?? '';
      final items = raw['items'] is List ? (raw['items'] as List) : const [];
      final hasData = content.isNotEmpty || items.isNotEmpty;
      if (!hasData) continue;

      if (type == 'objective') score += 15;
      if (type == 'education') score += 15;
      if (type == 'experience' || type == 'projects') score += 10;
      if (type == 'skills') score += 10;
      if (type == 'activities' || type == 'certificates' || type == 'awards') {
        score += 5;
      }
    }
    return score.clamp(15, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Quản lý & Tạo CV (TopCV Standard)',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
            fontSize: 17,
          ),
        ),
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewCv,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo CV mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<CvDocument>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa tải được danh sách CV',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.adaptiveTextSecondary, fontSize: 13),
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

            final items = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  // Banner Hero TopCV Builder
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CV Builder Chuẩn TopCV',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Tự động điền hồ sơ sinh viên & hoạt động ĐRL • Xuất PDF A4',
                                    style: TextStyle(
                                      color: Color(0xFFDBEAFE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFeatureBadge(Icons.bolt_rounded, 'Điền tự động 1 chạm'),
                            _buildFeatureBadge(Icons.view_column_rounded, 'Bố cục 2 cột TopCV'),
                            _buildFeatureBadge(Icons.picture_as_pdf_rounded, 'Xuất PDF chuẩn A4'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DANH SÁCH CV CỦA BẠN (${items.length})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppColors.adaptiveTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _createNewCv,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text(
                          'Tạo mới',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.adaptiveBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.badge_outlined, size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Bạn chưa có bản CV nào',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hệ thống sẽ hỗ trợ điền sẵn thông tin cá nhân, trường lớp và hoạt động ngoại khóa cho bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.adaptiveTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: _createNewCv,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Tạo CV chuẩn TopCV ngay'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final cv in items) _buildCvCard(cv),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvCard(CvDocument cv) {
    final completeness = _calculateCompleteness(cv);
    final fullName = cv.personal['full_name']?.toString().trim() ?? '';
    final position = cv.personal['job_position']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cv.isDefault ? AppColors.primary : AppColors.adaptiveBorder,
          width: cv.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditor(cv),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cv.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.adaptiveTextPrimary,
                                ),
                              ),
                            ),
                            if (cv.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'MẶC ĐỊNH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fullName.isNotEmpty
                              ? '$fullName${position.isNotEmpty ? " • $position" : ""}'
                              : 'Chạm để tự động điền thông tin cá nhân & chỉnh sửa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.adaptiveTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _openEditor(cv);
                      if (action == 'default') _setDefault(cv);
                      if (action == 'duplicate') _duplicate(cv);
                      if (action == 'delete') _delete(cv);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa CV')),
                      if (!cv.isDefault)
                        const PopupMenuItem(value: 'default', child: Text('Đặt làm mặc định')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Nhân bản CV')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa CV', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Thanh tiến độ hoàn thiện CV chuẩn TopCV
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Độ hoàn thiện hồ sơ CV',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adaptiveTextSecondary,
                    ),
                  ),
                  Text(
                    '$completeness%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completeness / 100,
                  minHeight: 7,
                  backgroundColor: AppColors.adaptiveCardSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openEditor(cv),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text(
                        'Thiết kế & Sửa CV',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                  ),
                  if (!cv.isDefault) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => _setDefault(cv),
                      child: const Text(
                        'Chọn mặc định',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
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

class _TopCvCreateSheet extends StatefulWidget {
  const _TopCvCreateSheet({required this.service});

  final StudentServicesService service;

  @override
  State<_TopCvCreateSheet> createState() => _TopCvCreateSheetState();
}

class _TopCvCreateSheetState extends State<_TopCvCreateSheet> {
  final _nameCtrl = TextEditingController(text: 'CV Ứng tuyển Thực tập sinh');
  late final Future<List<CvTemplate>> _templatesFuture = widget.service.cvTemplates();
  String _selectedTemplateId = 'modern';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên bản CV.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.service.createCv(
        name: name,
        templateId: _selectedTemplateId,
      );
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                'Tạo CV mới chuẩn TopCV',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thông tin cá nhân và trường lớp sẽ được hệ thống điền tự động cho bạn.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.adaptiveTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên bản CV',
                  hintText: 'VD: CV Thực tập sinh Kinh doanh / IT...',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn mẫu bố cục (Template)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<CvTemplate>>(
                future: _templatesFuture,
                builder: (context, snapshot) {
                  final templates = snapshot.data ??
                      const [
                        CvTemplate(
                          id: 'modern',
                          name: 'Modern TopCV (2 cột chuyên nghiệp)',
                        ),
                        CvTemplate(
                          id: 'minimal',
                          name: 'Minimalist ATS (1 cột chuẩn quốc tế)',
                        ),
                      ];
                  if (templates.isNotEmpty &&
                      !templates.any((t) => t.id == _selectedTemplateId)) {
                    _selectedTemplateId = templates.first.id;
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: templates.map((tpl) {
                      final isSelected = tpl.id == _selectedTemplateId;
                      return ChoiceChip(
                        label: Text(
                          tpl.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.adaptiveTextPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.adaptiveCardSubtle,
                        onSelected: (_) =>
                            setState(() => _selectedTemplateId = tpl.id),
                      );
                    }).toList(),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'Tạo & Tự động điền thông tin',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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

// ============================================================================
// TRÌNH SOẠN THẢO CV CHUẨN TOPCV (3 TAB: HỒ SƠ CÁ NHÂN - NỘI DUNG CV - XEM TRƯỚC & PDF)
// ============================================================================

class TopCvEditorScreen extends StatefulWidget {
  const TopCvEditorScreen({
    super.key,
    required this.service,
    required this.cv,
    this.autoFillOnInit = false,
  });

  final StudentServicesService service;
  final CvDocument cv;
  final bool autoFillOnInit;

  @override
  State<TopCvEditorScreen> createState() => _TopCvEditorScreenState();
}

class _TopCvEditorScreenState extends State<TopCvEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  // Thông tin cơ bản & Cá nhân
  late final TextEditingController _cvNameCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _jobPositionCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;

  // Nội dung đơn (Simple sections)
  late final TextEditingController _objectiveCtrl;
  late final TextEditingController _interestsCtrl;

  // Giao diện & Bố cục
  late String _templateId;
  late String _layout; // 'two-column' | 'one-column'
  late String _primaryColorHex;

  // Các danh sách mục chuẩn TopCV (List sections)
  late List<Map<String, dynamic>> _educationItems;
  late List<Map<String, dynamic>> _experienceItems;
  late List<Map<String, dynamic>> _projectItems;
  late List<Map<String, dynamic>> _skillItems;
  late List<Map<String, dynamic>> _activityItems;
  late List<Map<String, dynamic>> _certificateItems;
  late List<Map<String, dynamic>> _awardItems;
  late List<Map<String, dynamic>> _languageItems;
  late List<Map<String, dynamic>> _referenceItems;

  bool _saving = false;
  bool _autoFilling = false;
  bool _exportingPdf = false;

  static const List<Map<String, String>> _colorThemes = [
    {'name': 'Navy COFER', 'hex': '#1e3a8a'},
    {'name': 'Royal Blue', 'hex': '#2563eb'},
    {'name': 'Ocean Blue', 'hex': '#0284c7'},
    {'name': 'Executive Slate', 'hex': '#0f172a'},
    {'name': 'Emerald Pro', 'hex': '#0f766e'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.cv.personal;
    _cvNameCtrl = TextEditingController(text: widget.cv.name);
    _fullNameCtrl = TextEditingController(text: p['full_name']?.toString() ?? '');
    _jobPositionCtrl = TextEditingController(text: p['job_position']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: p['email']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _dobCtrl = TextEditingController(text: p['date_of_birth']?.toString() ?? '');
    _genderCtrl = TextEditingController(text: p['gender']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: p['address']?.toString() ?? '');
    _websiteCtrl = TextEditingController(text: p['website']?.toString() ?? '');

    _templateId = widget.cv.templateId.isEmpty ? 'modern' : widget.cv.templateId;
    _layout = widget.cv.appearance['layout']?.toString() == 'one-column'
        ? 'one-column'
        : 'two-column';
    _primaryColorHex =
        widget.cv.appearance['primary_color']?.toString().isNotEmpty == true
            ? widget.cv.appearance['primary_color'].toString()
            : '#1e3a8a';

    _objectiveCtrl = TextEditingController(text: _extractSimpleContent('objective'));
    _interestsCtrl = TextEditingController(text: _extractSimpleContent('interests'));

    _educationItems = _extractSectionItems('education');
    _experienceItems = _extractSectionItems('experience');
    _projectItems = _extractSectionItems('projects');
    _skillItems = _extractSectionItems('skills');
    _activityItems = _extractSectionItems('activities');
    _certificateItems = _extractSectionItems('certificates');
    _awardItems = _extractSectionItems('awards');
    _languageItems = _extractSectionItems('languages');
    _referenceItems = _extractSectionItems('references');

    // Tự động điền thông tin cá nhân của người dùng nếu trường đang trống
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillPersonalFromProfile(silent: !widget.autoFillOnInit);
    });
  }

  String _extractSimpleContent(String type) {
    for (final raw in widget.cv.sections) {
      if (raw is Map && raw['type']?.toString() == type) {
        return raw['content']?.toString() ?? '';
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _extractSectionItems(String type) {
    for (final raw in widget.cv.sections) {
      if (raw is Map && raw['type']?.toString() == type) {
        final list = raw['items'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    }
    return [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cvNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _jobPositionCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _objectiveCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  /// Tự động lấy dữ liệu Hồ sơ sinh viên & Hoạt động ĐRL để điền giúp người dùng (vẫn cho phép sửa)
  Future<void> _autoFillPersonalFromProfile({
    bool silent = false,
    bool overwrite = false,
  }) async {
    if (_autoFilling) return;
    setState(() => _autoFilling = true);

    try {
      final session = await AuthService().getSavedSession();
      final profile = await widget.service.fetchUserProfile();

      final name = (profile['name']?.toString().trim().isNotEmpty == true)
          ? profile['name'].toString().trim()
          : (session?.user.name ?? '');
      final email = (profile['email']?.toString().trim().isNotEmpty == true)
          ? profile['email'].toString().trim()
          : (session?.user.email ?? '');
      final phone = (profile['phone']?.toString().trim().isNotEmpty == true)
          ? profile['phone'].toString().trim()
          : (session?.user.phone ?? '');
      final address = profile['address']?.toString().trim() ?? '';
      final dob = profile['date_of_birth']?.toString().trim() ?? '';
      final gender = profile['gender']?.toString().trim() ?? '';
      final studentClass = (profile['class']?.toString().trim().isNotEmpty == true)
          ? profile['class'].toString().trim()
          : (session?.user.studentClass ?? '');
      final department = (profile['department']?.toString().trim().isNotEmpty == true)
          ? profile['department'].toString().trim()
          : (session?.user.department ?? '');
      final code = (profile['code']?.toString().trim().isNotEmpty == true)
          ? profile['code'].toString().trim()
          : (session?.user.code ?? '');

      bool changed = false;

      if ((overwrite || _fullNameCtrl.text.trim().isEmpty) && name.isNotEmpty) {
        _fullNameCtrl.text = name;
        changed = true;
      }
      if ((overwrite || _emailCtrl.text.trim().isEmpty) && email.isNotEmpty) {
        _emailCtrl.text = email;
        changed = true;
      }
      if ((overwrite || _phoneCtrl.text.trim().isEmpty) && phone.isNotEmpty) {
        _phoneCtrl.text = phone;
        changed = true;
      }
      if ((overwrite || _addressCtrl.text.trim().isEmpty) && address.isNotEmpty) {
        _addressCtrl.text = address;
        changed = true;
      }
      if ((overwrite || _dobCtrl.text.trim().isEmpty) && dob.isNotEmpty) {
        _dobCtrl.text = dob;
        changed = true;
      }
      if ((overwrite || _genderCtrl.text.trim().isEmpty) && gender.isNotEmpty) {
        _genderCtrl.text = gender;
        changed = true;
      }
      if (overwrite || _jobPositionCtrl.text.trim().isEmpty) {
        _jobPositionCtrl.text = department.isNotEmpty
            ? 'Thực tập sinh / Sinh viên $department'
            : 'Thực tập sinh / Sinh viên mới tốt nghiệp';
        changed = true;
      }
      if (overwrite || _objectiveCtrl.text.trim().isEmpty) {
        _objectiveCtrl.text =
            '• Ngắn hạn: Áp dụng kiến thức chuyên môn được đào tạo tại Trường Cao đẳng Kinh tế Đối ngoại${department.isNotEmpty ? " ($department)" : ""} và kỹ năng tích lũy từ các hoạt động rèn luyện vào thực tế công việc, hoàn thành tốt nhiệm vụ ở vị trí Thực tập sinh / Nhân viên chính thức.\n'
            '• Dài hạn: Không ngừng trau dồi nghiệp vụ chuyên sâu, nâng cao kỹ năng ngoại ngữ và đóng góp giá trị bền vững cho sự phát triển của doanh nghiệp.';
        changed = true;
      }

      // Tự động điền Học vấn tại Trường CĐ Kinh tế Đối ngoại nếu đang trống
      if (_educationItems.isEmpty) {
        _educationItems.add({
          'id': 'edu_${DateTime.now().millisecondsSinceEpoch}',
          'visible': true,
          'name': 'Trường Cao đẳng Kinh tế Đối ngoại (COFER)',
          'subtitle': [
            if (department.isNotEmpty) department,
            if (studentClass.isNotEmpty) 'Lớp $studentClass',
          ].join(' • '),
          'start_date': '2022',
          'end_date': 'Hiện tại',
          'description': [
            if (code.isNotEmpty) 'Mã số sinh viên: $code',
            'Tích cực tham gia phong trào rèn luyện sinh viên, nghiên cứu học tập và hoạt động ngoại khóa.',
          ].join('\n'),
        });
        changed = true;
      }

      // Tự động điền Kỹ năng mẫu nếu trống
      if (_skillItems.isEmpty && (overwrite || widget.autoFillOnInit)) {
        _skillItems.addAll([
          {
            'id': 'sk_1',
            'visible': true,
            'name': 'Tin học văn phòng (Word, Excel, PowerPoint)',
            'level': '85',
            'description': 'Soạn thảo văn bản, xử lý bảng tính và thiết kế bài thuyết trình.',
          },
          {
            'id': 'sk_2',
            'visible': true,
            'name': 'Làm việc nhóm & Giao tiếp thuyết trình',
            'level': '90',
            'description': 'Rèn luyện qua các hoạt động phong trào Đoàn - Hội và đồ án nhóm.',
          },
        ]);
        changed = true;
      }

      // Nếu người dùng bấm nút Đồng bộ hoặc tạo mới, tự động kéo cả các hoạt động ĐRL đã đăng ký
      if (overwrite || (_activityItems.isEmpty && widget.autoFillOnInit)) {
        final acts = await widget.service.fetchRegisteredActivitiesForCv();
        if (acts.isNotEmpty) {
          for (final act in acts.take(5)) {
            final actName = act['name']?.toString().trim() ?? '';
            if (actName.isEmpty) continue;
            final alreadyExists = _activityItems.any(
              (item) => item['name']?.toString() == actName,
            );
            if (!alreadyExists) {
              _activityItems.add({
                'id': 'act_${DateTime.now().microsecondsSinceEpoch}',
                'visible': true,
                'name': actName,
                'organization': act['department']?.toString().isNotEmpty == true
                    ? act['department'].toString()
                    : 'Trường CĐ Kinh tế Đối ngoại',
                'start_date': act['semester']?.toString() ?? 'Học kỳ',
                'end_date': 'Hoàn thành',
                'description':
                    'Tham gia tích cực hoạt động phong trào rèn luyện sinh viên (+${act['points'] ?? 0} điểm ĐRL).',
              });
              changed = true;
            }
          }
        }
      }

      if (mounted && changed) {
        setState(() {});
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã tự động điền thông tin cá nhân, học vấn & hoạt động! Bạn có thể chỉnh sửa bất kỳ mục nào.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _autoFilling = false);
    }
  }

  Map<String, dynamic> _buildPersonalMap() {
    return {
      ...widget.cv.personal,
      'full_name': _fullNameCtrl.text.trim(),
      'job_position': _jobPositionCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'date_of_birth': _dobCtrl.text.trim(),
      'gender': _genderCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
    };
  }

  Map<String, dynamic> _buildAppearanceMap() {
    return {
      ...widget.cv.appearance,
      'layout': _layout,
      'primary_color': _primaryColorHex,
      'paper_size': 'A4',
    };
  }

  List<Map<String, dynamic>> _buildSectionsList() {
    return [
      {
        'id': 'sec_objective',
        'type': 'objective',
        'title': 'Mục tiêu nghề nghiệp',
        'kind': 'simple',
        'visible': true,
        'column': 'main',
        'content': _objectiveCtrl.text.trim(),
        'items': const [],
      },
      {
        'id': 'sec_education',
        'type': 'education',
        'title': 'Học vấn',
        'kind': 'list',
        'visible': true,
        'column': 'main',
        'content': '',
        'items': _educationItems,
      },
      {
        'id': 'sec_experience',
        'type': 'experience',
        'title': 'Kinh nghiệm làm việc',
        'kind': 'list',
        'visible': true,
        'column': 'main',
        'content': '',
        'items': _experienceItems,
      },
      {
        'id': 'sec_projects',
        'type': 'projects',
        'title': 'Dự án thực tế',
        'kind': 'list',
        'visible': true,
        'column': 'main',
        'content': '',
        'items': _projectItems,
      },
      {
        'id': 'sec_activities',
        'type': 'activities',
        'title': 'Hoạt động ngoại khóa',
        'kind': 'list',
        'visible': true,
        'column': 'main',
        'content': '',
        'items': _activityItems,
      },
      {
        'id': 'sec_awards',
        'type': 'awards',
        'title': 'Giải thưởng & Danh hiệu',
        'kind': 'list',
        'visible': true,
        'column': 'main',
        'content': '',
        'items': _awardItems,
      },
      {
        'id': 'sec_skills',
        'type': 'skills',
        'title': 'Các kỹ năng',
        'kind': 'list',
        'visible': true,
        'column': 'sidebar',
        'content': '',
        'items': _skillItems,
      },
      {
        'id': 'sec_certificates',
        'type': 'certificates',
        'title': 'Chứng chỉ',
        'kind': 'list',
        'visible': true,
        'column': 'sidebar',
        'content': '',
        'items': _certificateItems,
      },
      {
        'id': 'sec_languages',
        'type': 'languages',
        'title': 'Ngoại ngữ',
        'kind': 'list',
        'visible': true,
        'column': 'sidebar',
        'content': '',
        'items': _languageItems,
      },
      {
        'id': 'sec_interests',
        'type': 'interests',
        'title': 'Sở thích',
        'kind': 'simple',
        'visible': true,
        'column': 'sidebar',
        'content': _interestsCtrl.text.trim(),
        'items': const [],
      },
      {
        'id': 'sec_references',
        'type': 'references',
        'title': 'Người tham chiếu',
        'kind': 'list',
        'visible': true,
        'column': 'sidebar',
        'content': '',
        'items': _referenceItems,
      },
    ];
  }

  Future<void> _saveCv({bool closeAfterSave = false}) async {
    setState(() => _saving = true);
    try {
      final updatedDoc = widget.cv.copyWith(
        name: _cvNameCtrl.text.trim().isEmpty
            ? 'CV sinh viên'
            : _cvNameCtrl.text.trim(),
        templateId: _templateId,
        personal: _buildPersonalMap(),
        appearance: _buildAppearanceMap(),
        sections: _buildSectionsList(),
      );
      await widget.service.updateCv(updatedDoc);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu CV thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      if (closeAfterSave) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu CV: ${e is ApiException ? e.message : e}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportAndSharePdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final pdfBytes = await _generateTopCvPdf();
      final safeName = (_fullNameCtrl.text.trim().isEmpty
              ? 'SinhVien'
              : _fullNameCtrl.text.trim())
          .replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'CV_TopCV_$safeName.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<Uint8List> _generateTopCvPdf() async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final primaryPdfColor = PdfColor.fromHex(_primaryColorHex);
    final personal = _buildPersonalMap();

    pw.Widget buildPdfSectionHeader(String title) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
        padding: const pw.EdgeInsets.only(bottom: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: primaryPdfColor, width: 1.5),
          ),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 11,
            color: primaryPdfColor,
          ),
        ),
      );
    }

    pw.Widget buildPdfListItems(
      List<Map<String, dynamic>> items, {
      String titleKey = 'name',
      String subKey = 'subtitle',
      String orgKey = 'organization',
    }) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) {
          final title = item[titleKey]?.toString() ?? '';
          final sub = (item[subKey]?.toString().isNotEmpty == true)
              ? item[subKey].toString()
              : (item[orgKey]?.toString() ?? '');
          final start = item['start_date']?.toString() ?? '';
          final end = item['end_date']?.toString() ?? '';
          final timeStr = [if (start.isNotEmpty) start, if (end.isNotEmpty) end]
              .join(' - ');
          final desc = item['description']?.toString() ?? '';

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        title,
                        style: pw.TextStyle(font: fontBold, fontSize: 10.5),
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      pw.Text(
                        timeStr,
                        style: pw.TextStyle(
                          font: fontItalic,
                          fontSize: 9.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
                if (sub.isNotEmpty)
                  pw.Text(
                    sub,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9.5,
                      color: primaryPdfColor,
                    ),
                  ),
                if (desc.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      desc,
                      style: pw.TextStyle(font: fontRegular, fontSize: 9.5),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (_) => [
          // Header Banner TopCV
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: primaryPdfColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (personal['full_name']?.toString().isNotEmpty == true
                          ? personal['full_name'].toString()
                          : 'HỌ VÀ TÊN SINH VIÊN')
                      .toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  personal['job_position']?.toString().isNotEmpty == true
                      ? personal['job_position'].toString()
                      : 'Vị trí ứng tuyển',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 11.5,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if ((personal['phone']?.toString() ?? '').isNotEmpty)
                      pw.Text(
                        'SĐT: ${personal['phone']}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    if ((personal['email']?.toString() ?? '').isNotEmpty)
                      pw.Text(
                        'Email: ${personal['email']}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    if ((personal['date_of_birth']?.toString() ?? '').isNotEmpty)
                      pw.Text(
                        'Ngày sinh: ${personal['date_of_birth']}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    if ((personal['address']?.toString() ?? '').isNotEmpty)
                      pw.Text(
                        'Địa chỉ: ${personal['address']}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    if ((personal['website']?.toString() ?? '').isNotEmpty)
                      pw.Text(
                        'Link: ${personal['website']}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (_objectiveCtrl.text.trim().isNotEmpty) ...[
            buildPdfSectionHeader('Mục tiêu nghề nghiệp'),
            pw.Text(
              _objectiveCtrl.text.trim(),
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
          ],

          if (_educationItems.isNotEmpty) ...[
            buildPdfSectionHeader('Học vấn'),
            buildPdfListItems(_educationItems),
          ],

          if (_experienceItems.isNotEmpty) ...[
            buildPdfSectionHeader('Kinh nghiệm làm việc'),
            buildPdfListItems(_experienceItems, subKey: 'organization'),
          ],

          if (_projectItems.isNotEmpty) ...[
            buildPdfSectionHeader('Dự án thực tế'),
            buildPdfListItems(_projectItems),
          ],

          if (_skillItems.isNotEmpty) ...[
            buildPdfSectionHeader('Các kỹ năng'),
            pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _skillItems.map((sk) {
                final name = sk['name']?.toString() ?? '';
                final lvl = sk['level']?.toString() ?? '';
                final desc = sk['description']?.toString() ?? '';
                return pw.Container(
                  width: 240,
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '$name${lvl.isNotEmpty ? " ($lvl%)" : ""}',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                      if (desc.isNotEmpty)
                        pw.Text(
                          desc,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (_activityItems.isNotEmpty) ...[
            buildPdfSectionHeader('Hoạt động ngoại khóa & Phong trào'),
            buildPdfListItems(_activityItems, subKey: 'organization'),
          ],

          if (_certificateItems.isNotEmpty) ...[
            buildPdfSectionHeader('Chứng chỉ'),
            buildPdfListItems(_certificateItems, subKey: 'organization'),
          ],

          if (_awardItems.isNotEmpty) ...[
            buildPdfSectionHeader('Giải thưởng & Danh hiệu'),
            buildPdfListItems(_awardItems, subKey: 'organization'),
          ],

          if (_languageItems.isNotEmpty) ...[
            buildPdfSectionHeader('Ngoại ngữ'),
            buildPdfListItems(_languageItems, subKey: 'level'),
          ],

          if (_interestsCtrl.text.trim().isNotEmpty) ...[
            buildPdfSectionHeader('Sở thích'),
            pw.Text(
              _interestsCtrl.text.trim(),
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
          ],

          if (_referenceItems.isNotEmpty) ...[
            buildPdfSectionHeader('Người tham chiếu'),
            buildPdfListItems(_referenceItems),
          ],
        ],
      ),
    );

    return doc.save();
  }

  Color get _themeColor {
    final clean = _primaryColorHex.replaceFirst('#', '');
    final val = int.tryParse('FF$clean', radix: 16);
    return val != null ? Color(val) : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thiết kế CV (TopCV Builder)',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _exportingPdf ? null : _exportAndSharePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'Xuất PDF chuẩn A4',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : () => _saveCv(closeAfterSave: true),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text(
                'Lưu CV',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.adaptiveTextSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_pin_rounded, size: 18), text: '1. Cá nhân'),
            Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 18), text: '2. Các mục CV'),
            Tab(icon: Icon(Icons.visibility_rounded, size: 18), text: '3. Xem & PDF'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab1PersonalAndDesign(),
          _buildTab2TopCvSections(),
          _buildTab3LivePreview(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: THÔNG TIN CÁ NHÂN (ĐIỀN TỰ ĐỘNG + CHO PHÉP SỬA) & MÀU SẮC / BỐ CỤC
  // ---------------------------------------------------------------------------
  Widget _buildTab1PersonalAndDesign() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Hộp hỗ trợ Tự động điền thông tin từ Hồ sơ sinh viên & Điểm rèn luyện
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hỗ trợ điền tự động thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.isDark ? Colors.white : const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tự động lấy Họ tên, Email, SĐT, Lớp, Khoa và Hoạt động ĐRL. Bạn có thể tự do chỉnh sửa mọi thông tin.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _autoFilling
                    ? null
                    : () => _autoFillPersonalFromProfile(silent: false, overwrite: true),
                child: _autoFilling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Điền tự động',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Thẻ Thiết kế & Màu sắc CV
        _buildEditorCard(
          title: 'Tên CV & Phong cách trình bày',
          icon: Icons.palette_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_cvNameCtrl, 'Tên bản CV quản lý', 'VD: CV Thực tập sinh Kinh doanh', Icons.badge_outlined),
              const SizedBox(height: 14),
              Text(
                'Bố cục trang CV (Layout)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLayoutOption(
                      label: '2 cột chuẩn TopCV',
                      value: 'two-column',
                      icon: Icons.view_sidebar_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLayoutOption(
                      label: '1 cột chuẩn ATS',
                      value: 'one-column',
                      icon: Icons.view_agenda_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Tông màu chủ đạo của CV',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _colorThemes.map((c) {
                  final hex = c['hex']!;
                  final isSelected = _primaryColorHex.toLowerCase() == hex.toLowerCase();
                  final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                  return InkWell(
                    onTap: () => setState(() => _primaryColorHex = hex),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.14) : AppColors.adaptiveCardSubtle,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? color : AppColors.adaptiveBorder,
                          width: isSelected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c['name']!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Thẻ Thông tin cá nhân (Đã điền sẵn + Cho phép sửa mọi trường)
        _buildEditorCard(
          title: 'Thông tin cá nhân (Cho phép sửa đổi)',
          icon: Icons.person_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_fullNameCtrl, 'Họ và tên ứng viên *', 'Nguyễn Văn A', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildTextField(
                _jobPositionCtrl,
                'Vị trí ứng tuyển *',
                'VD: Thực tập sinh Xuất nhập khẩu / Business Analyst',
                Icons.work_outline_rounded,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Thực tập sinh Kinh doanh Quốc tế',
                  'Thực tập sinh Logistics & Xuất nhập khẩu',
                  'Thực tập sinh Marketing',
                  'Thực tập sinh Kế toán - Kiểm toán',
                  'Thực tập sinh Công nghệ thông tin',
                ].map((pos) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(pos, style: const TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _jobPositionCtrl.text = pos),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_phoneCtrl, 'Số điện thoại *', '09xxxxxxxx', Icons.phone_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(_dobCtrl, 'Ngày sinh', 'dd/mm/yyyy', Icons.cake_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_emailCtrl, 'Email liên hệ *', 'sinhvien@cofer.edu.vn', Icons.mail_outline_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(_genderCtrl, 'Giới tính', 'Nam / Nữ', Icons.wc_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_addressCtrl, 'Địa chỉ hiện tại', 'Quận Phú Nhuận, TP. Hồ Chí Minh', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _buildTextField(_websiteCtrl, 'LinkedIn / GitHub / Portfolio', 'linkedin.com/in/...', Icons.link_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'Tiếp tục: Soạn các mục nội dung CV (TopCV)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = _layout == value;
    return InkWell(
      onTap: () => setState(() => _layout = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.adaptiveCardSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.adaptiveBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.adaptiveTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : AppColors.adaptiveTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: CÁC MỤC NỘI DUNG CHUẨN TOPCV (MỤC TIÊU, HỌC VẤN, KINH NGHIỆM, DỰ ÁN, KỸ NĂNG, HOẠT ĐỘNG, CHỨNG CHỈ, GIẢI THƯỞNG, NGOẠI NGỮ...)
  // ---------------------------------------------------------------------------
  Widget _buildTab2TopCvSections() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // 1. Mục tiêu nghề nghiệp
        _buildEditorCard(
          title: '1. Mục tiêu nghề nghiệp',
          icon: Icons.track_changes_rounded,
          trailing: PopupMenuButton<String>(
            tooltip: 'Chọn mẫu mục tiêu chuẩn TopCV',
            onSelected: (tpl) {
              setState(() => _objectiveCtrl.text = tpl);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value:
                    '• Ngắn hạn: Áp dụng kiến thức chuyên ngành được đào tạo tại Trường CĐ Kinh tế Đối ngoại vào thực tế công việc ở vị trí Thực tập sinh, nhanh chóng nắm bắt quy trình nghiệp vụ của công ty.\n• Dài hạn: Trở thành nhân sự chính thức có chuyên môn vững vàng, đóng góp tích cực vào doanh thu và sự phát triển bền vững của doanh nghiệp.',
                child: Text('Mẫu 1: Thực tập sinh / Sinh viên mới ra trường'),
              ),
              const PopupMenuItem(
                value:
                    '• Ngắn hạn: Hoàn thành xuất sắc kỳ thực tập với tinh thần trách nhiệm cao, phát huy kỹ năng giao tiếp, ngoại ngữ và làm việc nhóm đã rèn luyện.\n• Dài hạn: Phát triển chuyên sâu trong lĩnh vực chuyên môn và gắn bó lâu dài cùng tổ chức.',
                child: Text('Mẫu 2: Ứng tuyển Doanh nghiệp / Tập đoàn'),
              ),
            ],
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Gợi ý mẫu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
          child: TextField(
            controller: _objectiveCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Mô tả mục tiêu ngắn hạn (3-6 tháng) và dài hạn (1-3 năm) của bạn...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Học vấn (Education)
        _buildListSectionCard(
          title: '2. Học vấn (Education)',
          icon: Icons.school_outlined,
          items: _educationItems,
          emptyHint: 'Thêm thông tin trường đại học/cao đẳng, chuyên ngành, GPA...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Học vấn',
            fields: const [
              _FieldDef('name', 'Trường / Cơ sở đào tạo *', 'Trường Cao đẳng Kinh tế Đối ngoại'),
              _FieldDef('subtitle', 'Khoa / Chuyên ngành *', 'Kinh doanh Quốc tế / CNTT'),
              _FieldDef('start_date', 'Năm bắt đầu', '2022'),
              _FieldDef('end_date', 'Năm kết thúc', 'Hiện tại'),
              _FieldDef('description', 'Thành tích / GPA / Mô tả', 'GPA: 3.4/4.0, Điểm rèn luyện Xuất sắc...', maxLines: 3),
            ],
            onSave: (item) => setState(() => _educationItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Chỉnh sửa Học vấn',
            initial: current,
            fields: const [
              _FieldDef('name', 'Trường / Cơ sở đào tạo *', ''),
              _FieldDef('subtitle', 'Khoa / Chuyên ngành *', ''),
              _FieldDef('start_date', 'Năm bắt đầu', ''),
              _FieldDef('end_date', 'Năm kết thúc', ''),
              _FieldDef('description', 'Thành tích / GPA / Mô tả', '', maxLines: 3),
            ],
            onSave: (item) => setState(() => _educationItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _educationItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 3. Kinh nghiệm làm việc (Experience)
        _buildListSectionCard(
          title: '3. Kinh nghiệm làm việc',
          icon: Icons.business_center_outlined,
          items: _experienceItems,
          emptyHint: 'Thêm công việc thực tập, part-time, cộng tác viên...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Kinh nghiệm làm việc',
            fields: const [
              _FieldDef('name', 'Vị trí công việc *', 'Thực tập sinh / Cộng tác viên...'),
              _FieldDef('organization', 'Tên Công ty / Tổ chức *', 'Công ty TNHH...'),
              _FieldDef('start_date', 'Bắt đầu', '06/2025'),
              _FieldDef('end_date', 'Kết thúc', '09/2025'),
              _FieldDef('description', 'Mô tả công việc & Kết quả đạt được', '• Hỗ trợ xử lý chứng từ...\n• Đạt 110% KPI được giao...', maxLines: 4),
            ],
            onSave: (item) => setState(() => _experienceItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Kinh nghiệm làm việc',
            initial: current,
            fields: const [
              _FieldDef('name', 'Vị trí công việc *', ''),
              _FieldDef('organization', 'Tên Công ty / Tổ chức *', ''),
              _FieldDef('start_date', 'Bắt đầu', ''),
              _FieldDef('end_date', 'Kết thúc', ''),
              _FieldDef('description', 'Mô tả công việc & Kết quả đạt được', '', maxLines: 4),
            ],
            onSave: (item) => setState(() => _experienceItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _experienceItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 4. Dự án thực tế / Đồ án môn học (Projects)
        _buildListSectionCard(
          title: '4. Dự án thực tế / Đồ án',
          icon: Icons.rocket_launch_outlined,
          items: _projectItems,
          emptyHint: 'Thêm đồ án môn học, dự án nghiên cứu khoa học, khởi nghiệp...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Dự án',
            fields: const [
              _FieldDef('name', 'Tên dự án / Đồ án *', 'Hệ thống quản lý...'),
              _FieldDef('subtitle', 'Vai trò & Công nghệ / Công cụ', 'Trưởng nhóm • Excel / Python / Flutter'),
              _FieldDef('start_date', 'Bắt đầu', '01/2026'),
              _FieldDef('end_date', 'Kết thúc', '05/2026'),
              _FieldDef('description', 'Mô tả dự án & Kết quả', 'Phân tích quy trình, xây dựng giải pháp...', maxLines: 3),
            ],
            onSave: (item) => setState(() => _projectItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Dự án',
            initial: current,
            fields: const [
              _FieldDef('name', 'Tên dự án / Đồ án *', ''),
              _FieldDef('subtitle', 'Vai trò & Công nghệ / Công cụ', ''),
              _FieldDef('start_date', 'Bắt đầu', ''),
              _FieldDef('end_date', 'Kết thúc', ''),
              _FieldDef('description', 'Mô tả dự án & Kết quả', '', maxLines: 3),
            ],
            onSave: (item) => setState(() => _projectItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _projectItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 5. Các kỹ năng (Skills)
        _buildListSectionCard(
          title: '5. Kỹ năng chuyên môn & Kỹ năng mềm',
          icon: Icons.psychology_outlined,
          items: _skillItems,
          emptyHint: 'Thêm kỹ năng chuyên ngành, tin học, giao tiếp, giải quyết vấn đề...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Kỹ năng',
            fields: const [
              _FieldDef('name', 'Tên kỹ năng *', 'VD: Nghiệp vụ Xuất nhập khẩu / Microsoft Excel'),
              _FieldDef('level', 'Mức độ thành thạo (0 - 100)', '85'),
              _FieldDef('description', 'Mô tả chi tiết', 'Sử dụng thành thạo PivotTable, VLOOKUP, báo cáo...'),
            ],
            onSave: (item) => setState(() => _skillItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Kỹ năng',
            initial: current,
            fields: const [
              _FieldDef('name', 'Tên kỹ năng *', ''),
              _FieldDef('level', 'Mức độ thành thạo (0 - 100)', '85'),
              _FieldDef('description', 'Mô tả chi tiết', ''),
            ],
            onSave: (item) => setState(() => _skillItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _skillItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 6. Hoạt động ngoại khóa & Phong trào ĐRL (Activities)
        _buildListSectionCard(
          title: '6. Hoạt động ngoại khóa & Rèn luyện',
          icon: Icons.volunteer_activism_outlined,
          items: _activityItems,
          emptyHint: 'Thêm hoạt động Đoàn - Hội, Tình nguyện, CLB hoặc lấy tự động từ ĐRL.',
          extraAction: TextButton.icon(
            onPressed: _autoFilling
                ? null
                : () => _autoFillPersonalFromProfile(silent: false, overwrite: true),
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Đồng bộ từ ĐRL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          onAdd: () => _openItemDialog(
            title: 'Thêm Hoạt động ngoại khóa',
            fields: const [
              _FieldDef('name', 'Tên hoạt động / Sự kiện *', 'Chiến dịch Xuân Tình Nguyện / Hội thảo...'),
              _FieldDef('organization', 'Đơn vị tổ chức', 'Đoàn Trường CĐ Kinh tế Đối ngoại'),
              _FieldDef('start_date', 'Thời gian', '2025'),
              _FieldDef('end_date', 'Vai trò', 'Tình nguyện viên / Ban tổ chức'),
              _FieldDef('description', 'Đóng góp & Kết quả', 'Tham gia tổ chức, hỗ trợ sinh viên...', maxLines: 3),
            ],
            onSave: (item) => setState(() => _activityItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Hoạt động ngoại khóa',
            initial: current,
            fields: const [
              _FieldDef('name', 'Tên hoạt động / Sự kiện *', ''),
              _FieldDef('organization', 'Đơn vị tổ chức', ''),
              _FieldDef('start_date', 'Thời gian', ''),
              _FieldDef('end_date', 'Vai trò', ''),
              _FieldDef('description', 'Đóng góp & Kết quả', '', maxLines: 3),
            ],
            onSave: (item) => setState(() => _activityItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _activityItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 7. Chứng chỉ (Certificates)
        _buildListSectionCard(
          title: '7. Chứng chỉ chuyên môn & Tin học',
          icon: Icons.verified_outlined,
          items: _certificateItems,
          emptyHint: 'Thêm chứng chỉ TOEIC, IELTS, MOS, Nghiệp vụ...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Chứng chỉ',
            fields: const [
              _FieldDef('name', 'Tên chứng chỉ *', 'VD: Chứng chỉ TOEIC 650 / Tin học MOS'),
              _FieldDef('organization', 'Tổ chức cấp', 'IIG Việt Nam'),
              _FieldDef('end_date', 'Năm cấp', '2025'),
              _FieldDef('description', 'Điểm số / Ghi chú', ''),
            ],
            onSave: (item) => setState(() => _certificateItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Chứng chỉ',
            initial: current,
            fields: const [
              _FieldDef('name', 'Tên chứng chỉ *', ''),
              _FieldDef('organization', 'Tổ chức cấp', ''),
              _FieldDef('end_date', 'Năm cấp', ''),
              _FieldDef('description', 'Điểm số / Ghi chú', ''),
            ],
            onSave: (item) => setState(() => _certificateItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _certificateItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 8. Giải thưởng & Danh hiệu (Awards)
        _buildListSectionCard(
          title: '8. Giải thưởng & Danh hiệu sinh viên',
          icon: Icons.emoji_events_outlined,
          items: _awardItems,
          emptyHint: 'Thêm danh hiệu Sinh viên 5 tốt, Học bổng khuyến khích học tập...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Giải thưởng / Danh hiệu',
            fields: const [
              _FieldDef('name', 'Tên giải thưởng / Danh hiệu *', 'Danh hiệu Sinh viên 5 Tốt cấp Trường'),
              _FieldDef('organization', 'Đơn vị trao tặng', 'Trường Cao đẳng Kinh tế Đối ngoại'),
              _FieldDef('end_date', 'Năm đạt được', '2025'),
              _FieldDef('description', 'Mô tả thành tích', 'Đạt chuẩn 5 tiêu chí Đạo đức, Học tập, Thể lực, Tình nguyện, Hội nhập.'),
            ],
            onSave: (item) => setState(() => _awardItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Giải thưởng / Danh hiệu',
            initial: current,
            fields: const [
              _FieldDef('name', 'Tên giải thưởng / Danh hiệu *', ''),
              _FieldDef('organization', 'Đơn vị trao tặng', ''),
              _FieldDef('end_date', 'Năm đạt được', ''),
              _FieldDef('description', 'Mô tả thành tích', ''),
            ],
            onSave: (item) => setState(() => _awardItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _awardItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        // 9. Ngoại ngữ (Languages) & Sở thích (Interests)
        _buildListSectionCard(
          title: '9. Ngoại ngữ',
          icon: Icons.translate_rounded,
          items: _languageItems,
          emptyHint: 'Thêm Tiếng Anh, Tiếng Trung, Tiếng Nhật, Tiếng Hàn...',
          onAdd: () => _openItemDialog(
            title: 'Thêm Ngoại ngữ',
            fields: const [
              _FieldDef('name', 'Ngôn ngữ *', 'Tiếng Anh'),
              _FieldDef('level', 'Trình độ', 'Giao tiếp & đọc hiểu tài liệu chuyên ngành tốt'),
            ],
            onSave: (item) => setState(() => _languageItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Ngoại ngữ',
            initial: current,
            fields: const [
              _FieldDef('name', 'Ngôn ngữ *', ''),
              _FieldDef('level', 'Trình độ', ''),
            ],
            onSave: (item) => setState(() => _languageItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _languageItems.removeAt(idx)),
        ),
        const SizedBox(height: 16),

        _buildEditorCard(
          title: '10. Sở thích cá nhân',
          icon: Icons.auto_stories_outlined,
          child: TextField(
            controller: _interestsCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'VD: Đọc sách kinh tế, tham gia hoạt động tình nguyện, thể thao...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 11. Người tham chiếu (References)
        _buildListSectionCard(
          title: '11. Người tham chiếu (References)',
          icon: Icons.contact_phone_outlined,
          items: _referenceItems,
          emptyHint: 'Thêm giảng viên hướng dẫn hoặc quản lý trực tiếp (không bắt buộc).',
          onAdd: () => _openItemDialog(
            title: 'Thêm Người tham chiếu',
            fields: const [
              _FieldDef('name', 'Họ tên người tham chiếu *', 'ThS. Nguyễn Văn B'),
              _FieldDef('subtitle', 'Chức vụ / Đơn vị', 'Giảng viên Khoa... - Trường CĐ Kinh tế Đối ngoại'),
              _FieldDef('description', 'Email / Số điện thoại liên hệ', 'Email: ... | SĐT: ...'),
            ],
            onSave: (item) => setState(() => _referenceItems.add(item)),
          ),
          onEdit: (idx, current) => _openItemDialog(
            title: 'Sửa Người tham chiếu',
            initial: current,
            fields: const [
              _FieldDef('name', 'Họ tên người tham chiếu *', ''),
              _FieldDef('subtitle', 'Chức vụ / Đơn vị', ''),
              _FieldDef('description', 'Email / Số điện thoại liên hệ', ''),
            ],
            onSave: (item) => setState(() => _referenceItems[idx] = item),
          ),
          onDelete: (idx) => setState(() => _referenceItems.removeAt(idx)),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Xem trước CV', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : () => _saveCv(closeAfterSave: false),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: XEM TRƯỚC BẢN IN TOPCV A4 & XUẤT PDF
  // ---------------------------------------------------------------------------
  Widget _buildTab3LivePreview() {
    final themeColor = _themeColor;
    final fullName = _fullNameCtrl.text.trim().isEmpty
        ? 'HỌ VÀ TÊN SINH VIÊN'
        : _fullNameCtrl.text.trim().toUpperCase();
    final position = _jobPositionCtrl.text.trim().isEmpty
        ? 'Vị trí ứng tuyển'
        : _jobPositionCtrl.text.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Thanh công cụ xuất PDF & Lưu
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _exportingPdf ? null : _exportAndSharePdf,
                icon: _exportingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Tải / Chia sẻ PDF Chuẩn A4',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : () => _saveCv(closeAfterSave: false),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tờ giấy A4 TopCV Preview
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header TopCV
              Container(
                padding: const EdgeInsets.all(20),
                color: themeColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                position,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (_phoneCtrl.text.trim().isNotEmpty)
                          _buildPreviewContactChip(Icons.phone_rounded, _phoneCtrl.text.trim()),
                        if (_emailCtrl.text.trim().isNotEmpty)
                          _buildPreviewContactChip(Icons.email_rounded, _emailCtrl.text.trim()),
                        if (_dobCtrl.text.trim().isNotEmpty)
                          _buildPreviewContactChip(Icons.cake_rounded, _dobCtrl.text.trim()),
                        if (_addressCtrl.text.trim().isNotEmpty)
                          _buildPreviewContactChip(Icons.place_rounded, _addressCtrl.text.trim()),
                        if (_websiteCtrl.text.trim().isNotEmpty)
                          _buildPreviewContactChip(Icons.language_rounded, _websiteCtrl.text.trim()),
                      ],
                    ),
                  ],
                ),
              ),

              // Body CV
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_objectiveCtrl.text.trim().isNotEmpty) ...[
                      _buildPreviewSectionTitle('MỤC TIÊU NGHỀ NGHIỆP', themeColor),
                      Text(
                        _objectiveCtrl.text.trim(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_educationItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('HỌC VẤN', themeColor),
                      ..._educationItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_experienceItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('KINH NGHIỆM LÀM VIỆC', themeColor),
                      ..._experienceItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_projectItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('DỰ ÁN THỰC TẾ', themeColor),
                      ..._projectItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_skillItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('CÁC KỸ NĂNG', themeColor),
                      ..._skillItems.map((sk) {
                        final lvl = (int.tryParse(sk['level']?.toString() ?? '80') ?? 80)
                            .clamp(10, 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sk['name']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$lvl%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: themeColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: lvl / 100,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    if (_activityItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('HOẠT ĐỘNG NGOẠI KHÓA', themeColor),
                      ..._activityItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_certificateItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('CHỨNG CHỈ', themeColor),
                      ..._certificateItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_awardItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('GIẢI THƯỞNG & DANH HIỆU', themeColor),
                      ..._awardItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_languageItems.isNotEmpty) ...[
                      _buildPreviewSectionTitle('NGOẠI NGỮ', themeColor),
                      ..._languageItems.map((e) => _buildPreviewItem(e, themeColor)),
                      const SizedBox(height: 10),
                    ],
                    if (_interestsCtrl.text.trim().isNotEmpty) ...[
                      _buildPreviewSectionTitle('SỞ THÍCH', themeColor),
                      Text(
                        _interestsCtrl.text.trim(),
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContactChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSectionTitle(String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 1.8)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(Map<String, dynamic> item, Color themeColor) {
    final title = item['name']?.toString() ?? '';
    final sub = (item['subtitle']?.toString().isNotEmpty == true)
        ? item['subtitle'].toString()
        : (item['organization']?.toString().isNotEmpty == true
            ? item['organization'].toString()
            : (item['level']?.toString() ?? ''));
    final start = item['start_date']?.toString() ?? '';
    final end = item['end_date']?.toString() ?? '';
    final timeStr = [if (start.isNotEmpty) start, if (end.isNotEmpty) end].join(' - ');
    final desc = item['description']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          if (sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ),
          if (desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildEditorCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildListSectionCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String emptyHint,
    required VoidCallback onAdd,
    required void Function(int index, Map<String, dynamic> item) onEdit,
    required void Function(int index) onDelete,
    Widget? extraAction,
  }) {
    return _buildEditorCard(
      title: '$title (${items.length})',
      icon: icon,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extraAction != null) extraAction,
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
        ],
      ),
      child: items.isEmpty
          ? InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.adaptiveCardSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.adaptiveBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        emptyHint,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.adaptiveTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: List.generate(items.length, (idx) {
                final item = items[idx];
                final itemName = item['name']?.toString() ?? 'Mục #${idx + 1}';
                final sub = (item['subtitle']?.toString().isNotEmpty == true)
                    ? item['subtitle'].toString()
                    : (item['organization']?.toString().isNotEmpty == true
                        ? item['organization'].toString()
                        : (item['level']?.toString() ?? ''));
                final start = item['start_date']?.toString() ?? '';
                final end = item['end_date']?.toString() ?? '';
                final time = [if (start.isNotEmpty) start, if (end.isNotEmpty) end].join(' - ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveCardSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.adaptiveBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.adaptiveTextPrimary,
                              ),
                            ),
                            if (sub.isNotEmpty || time.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [if (sub.isNotEmpty) sub, if (time.isNotEmpty) time].join(' • '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                            if ((item['description']?.toString() ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item['description'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.adaptiveTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onEdit(idx, item),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onDelete(idx),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  void _openItemDialog({
    required String title,
    required List<_FieldDef> fields,
    Map<String, dynamic>? initial,
    required void Function(Map<String, dynamic> value) onSave,
  }) {
    final controllers = <String, TextEditingController>{
      for (final f in fields)
        f.key: TextEditingController(text: initial?[f.key]?.toString() ?? ''),
    };

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final f in fields) ...[
                    TextField(
                      controller: controllers[f.key],
                      maxLines: f.maxLines,
                      decoration: InputDecoration(
                        labelText: f.label,
                        hintText: f.hint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final result = <String, dynamic>{
                          'id': initial?['id'] ??
                              'item_${DateTime.now().microsecondsSinceEpoch}',
                          'visible': true,
                          for (final f in fields)
                            f.key: controllers[f.key]!.text.trim(),
                        };
                        Navigator.of(sheetCtx).pop();
                        onSave(result);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Lưu mục này',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldDef {
  const _FieldDef(this.key, this.label, this.hint, {this.maxLines = 1});

  final String key;
  final String label;
  final String hint;
  final int maxLines;
}
