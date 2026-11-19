import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/drl_models.dart';
import '../data/drl_service.dart';
import 'drl_score_format.dart';

class DrlSelfAssessmentScreen extends StatefulWidget {
  const DrlSelfAssessmentScreen({
    super.key,
    required this.service,
    required this.semesterId,
  });

  final DrlService service;
  final String semesterId;

  @override
  State<DrlSelfAssessmentScreen> createState() => _DrlSelfAssessmentScreenState();
}

class _DrlSelfAssessmentScreenState extends State<DrlSelfAssessmentScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<DrlEvidenceUpload>> _uploads = {};
  final Map<String, List<String>> _removeEvidence = {};

  DrlSelfAssessmentForm? _form;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final form = await widget.service.fetchSelfAssessment(widget.semesterId);
      _applyForm(form);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được phiếu tự đánh giá.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyForm(DrlSelfAssessmentForm form) {
    for (final section in form.criteriaScore.sections) {
      for (final criterion in section.criteria.where((item) => item.studentMayFill)) {
        final controller = _controllers.putIfAbsent(criterion.key, TextEditingController.new);
        controller.text = criterion.score == null ? '' : formatScore(criterion.score!);
      }
    }

    setState(() {
      _form = form;
      _uploads.clear();
      _removeEvidence.clear();
    });
  }

  Future<void> _pickEvidence(DrlCriterion criterion) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) {
      return;
    }

    final picked = <DrlEvidenceUpload>[];
    for (final file in result.files) {
      if (file.bytes == null) continue;
      final compressed = await ImageCompressor.compressImage(
        fileName: file.name,
        bytes: file.bytes!,
      );
      picked.add(DrlEvidenceUpload(name: compressed.name, bytes: compressed.bytes));
    }

    if (picked.isEmpty) {
      setState(() => _errorMessage = 'Không đọc được file minh chứng đã chọn.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _uploads.putIfAbsent(criterion.key, () => []).addAll(picked);
    });
  }

  Future<void> _save() async {
    final form = _form;
    if (form == null || !form.mayEdit) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final scores = <String, String>{};
    for (final section in form.criteriaScore.sections) {
      for (final criterion in section.criteria.where((item) => item.studentMayFill)) {
        scores[criterion.key] = _controllers[criterion.key]?.text.trim() ?? '';
      }
    }

    try {
      final saved = await widget.service.saveSelfAssessment(
        semesterId: widget.semesterId,
        scores: scores,
        removeEvidence: _removeEvidence,
        uploads: _uploads,
      );
      _applyForm(saved);
      setState(() => _successMessage = 'Đã lưu phiếu tự đánh giá.');
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không lưu được phiếu tự đánh giá.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleRemoveEvidence(String key, String path) {
    setState(() {
      final paths = _removeEvidence.putIfAbsent(key, () => []);
      if (paths.contains(path)) {
        paths.remove(path);
      } else {
        paths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveBackground,
        surfaceTintColor: AppColors.adaptiveBackground,
        title: const Text(
          'Tự đánh giá DRL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && form == null
                ? _Message(message: _errorMessage!, isError: true)
                : form == null
                    ? const _Message(message: 'Chưa có dữ liệu phiếu.', isError: false)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 760;
                          return ListView(
                            padding: EdgeInsets.fromLTRB(isWide ? 32 : 18, 12, isWide ? 32 : 18, 28),
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 920),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _HeaderCard(form: form),
                                      if (_errorMessage != null) ...[
                                        const SizedBox(height: 12),
                                        _Banner(message: _errorMessage!, color: AppColors.danger),
                                      ],
                                      if (_successMessage != null) ...[
                                        const SizedBox(height: 12),
                                        _Banner(message: _successMessage!, color: const Color(0xFF059669)),
                                      ],
                                      const SizedBox(height: 18),
                                      ...form.criteriaScore.sections.map(
                                        (section) => Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: _SectionCard(
                                            section: section,
                                            mayEdit: form.mayEdit,
                                            controllers: _controllers,
                                            uploads: _uploads,
                                            removeEvidence: _removeEvidence,
                                            onPickEvidence: _pickEvidence,
                                            onToggleRemove: _toggleRemoveEvidence,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      PrimaryButton(
                                        label: form.mayEdit ? 'Lưu tự đánh giá' : 'Phiếu đang khóa',
                                        isLoading: _isSaving,
                                        onPressed: form.mayEdit ? _save : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.form});

  final DrlSelfAssessmentForm form;

  @override
  Widget build(BuildContext context) {
    final score = form.criteriaScore.studentTotal;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Colors.white, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.semester.name,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  formatScore(score),
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                ),
                Text(
                  form.mayEdit
                      ? (form.deadlineLabel.isEmpty ? 'Có thể chỉnh sửa' : 'Hạn: ${form.deadlineLabel}')
                      : (form.isApproved ? 'Phiếu đã duyệt' : 'Phiếu đang khóa'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.mayEdit,
    required this.controllers,
    required this.uploads,
    required this.removeEvidence,
    required this.onPickEvidence,
    required this.onToggleRemove,
  });

  final DrlCriteriaSection section;
  final bool mayEdit;
  final Map<String, TextEditingController> controllers;
  final Map<String, List<DrlEvidenceUpload>> uploads;
  final Map<String, List<String>> removeEvidence;
  final ValueChanged<DrlCriterion> onPickEvidence;
  final void Function(String key, String path) onToggleRemove;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Text(
          'Mục ${section.section}',
          style: TextStyle(color: AppColors.adaptiveTextPrimary, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Tạm tính: ${formatScore(section.capped)} điểm',
          style: TextStyle(color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w700),
        ),
        children: section.criteria
            .map(
              (criterion) => _CriterionEditor(
                criterion: criterion,
                mayEdit: mayEdit,
                controller: controllers[criterion.key],
                uploads: uploads[criterion.key] ?? const [],
                removedPaths: removeEvidence[criterion.key] ?? const [],
                onPickEvidence: () => onPickEvidence(criterion),
                onToggleRemove: (path) => onToggleRemove(criterion.key, path),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CriterionEditor extends StatelessWidget {
  const _CriterionEditor({
    required this.criterion,
    required this.mayEdit,
    required this.controller,
    required this.uploads,
    required this.removedPaths,
    required this.onPickEvidence,
    required this.onToggleRemove,
  });

  final DrlCriterion criterion;
  final bool mayEdit;
  final TextEditingController? controller;
  final List<DrlEvidenceUpload> uploads;
  final List<String> removedPaths;
  final VoidCallback onPickEvidence;
  final ValueChanged<String> onToggleRemove;

  @override
  Widget build(BuildContext context) {
    final editable = mayEdit && criterion.studentMayFill && controller != null;
    final showEvidence = criterion.showEvidence || criterion.requiresEvidence || criterion.evidenceStored.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            criterion.label.isEmpty ? criterion.key : criterion.label,
            style: TextStyle(color: AppColors.adaptiveTextPrimary, fontWeight: FontWeight.w900),
          ),
          if (criterion.note.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(criterion.note, style: TextStyle(color: AppColors.adaptiveTextSecondary, height: 1.35)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: 'Max ${formatScore(criterion.maxDisplay)}', color: AppColors.adaptiveTextSecondary),
              if (!criterion.studentMayFill)
                _MiniBadge(label: 'Tự động: ${_scoreOrDash(criterion.effectiveScore)}', color: AppColors.primary),
              if (criterion.requiresEvidence) _MiniBadge(label: 'Cần minh chứng', color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 12),
          if (editable)
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Điểm tự đánh giá',
                hintText: '${formatScore(criterion.minScore)} - ${formatScore(criterion.maxScore)}',
                prefixIcon: const Icon(Icons.scoreboard_outlined),
              ),
            )
          else
            Text(
              'Điểm sinh viên: ${_scoreOrDash(criterion.effectiveScore)}',
              style: TextStyle(color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w800),
            ),
          if (showEvidence) ...[
            const SizedBox(height: 12),
            _EvidenceList(
              criterion: criterion,
              uploads: uploads,
              removedPaths: removedPaths,
              mayEdit: mayEdit,
              onPickEvidence: onPickEvidence,
              onToggleRemove: onToggleRemove,
            ),
          ],
        ],
      ),
    );
  }

  String _scoreOrDash(double? value) => value == null ? '-' : formatScore(value);
}

class _EvidenceList extends StatelessWidget {
  const _EvidenceList({
    required this.criterion,
    required this.uploads,
    required this.removedPaths,
    required this.mayEdit,
    required this.onPickEvidence,
    required this.onToggleRemove,
  });

  final DrlCriterion criterion;
  final List<DrlEvidenceUpload> uploads;
  final List<String> removedPaths;
  final bool mayEdit;
  final VoidCallback onPickEvidence;
  final ValueChanged<String> onToggleRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Minh chứng',
                style: TextStyle(color: AppColors.adaptiveTextPrimary, fontWeight: FontWeight.w900),
              ),
            ),
            if (mayEdit && criterion.studentMayFill)
              TextButton.icon(
                onPressed: onPickEvidence,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Chọn file'),
              ),
          ],
        ),
        if (criterion.evidenceStored.isEmpty && uploads.isEmpty)
          Text(
            'Chưa có minh chứng.',
            style: TextStyle(color: AppColors.adaptiveTextSecondary, fontWeight: FontWeight.w700),
          ),
        ...criterion.evidenceStored.map(
          (file) => _EvidenceChip(
            label: file.name.isEmpty ? file.path : file.name,
            isRemoved: removedPaths.contains(file.path),
            onRemove: mayEdit && criterion.studentMayFill ? () => onToggleRemove(file.path) : null,
          ),
        ),
        ...uploads.map((file) => _EvidenceChip(label: 'Mới: ${file.name}', isRemoved: false)),
      ],
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({
    required this.label,
    required this.isRemoved,
    this.onRemove,
  });

  final String label;
  final bool isRemoved;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRemoved ? AppColors.danger.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isRemoved ? Icons.delete_outline_rounded : Icons.insert_drive_file_outlined,
            color: isRemoved ? AppColors.danger : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRemoved ? 'Sẽ xóa: $label' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRemoved ? AppColors.danger : AppColors.adaptiveTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: isRemoved ? 'Hoàn tác' : 'Xóa khi lưu',
              onPressed: onRemove,
              icon: Icon(isRemoved ? Icons.undo_rounded : Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

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
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
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

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.adaptiveTextSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
