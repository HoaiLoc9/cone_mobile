import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../data/appellation_models.dart';
import '../data/appellation_service.dart';

class AppellationDetailScreen extends StatefulWidget {
  const AppellationDetailScreen({
    super.key,
    required this.service,
    required this.appellationId,
  });

  final AppellationService service;
  final String appellationId;

  @override
  State<AppellationDetailScreen> createState() => _AppellationDetailScreenState();
}

class _AppellationDetailScreenState extends State<AppellationDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _checks = {};
  final Map<String, List<AppellationUpload>> _formUploads = {};
  final Map<String, List<String>> _removeFormFiles = {};
  final Map<String, AppellationUpload> _legacyUploads = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  AppellationDetail? _detail;

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
      final detail = await widget.service.fetchDetail(widget.appellationId);
      _applyDetail(detail);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được chi tiết danh hiệu.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyDetail(AppellationDetail detail) {
    final registration = detail.registration;
    for (final field in detail.appellation.formSchema?.fields ?? const <AppellationFormField>[]) {
      if (field.key.isEmpty || field.type == 'section' || field.type == 'file' || field.type == 'criterion') {
        continue;
      }
      if (field.type == 'checkbox') {
        final value = registration?.formData[field.key]?.toString() ?? '';
        _checks[field.key] = ['1', 'true', 'yes', 'on'].contains(value.toLowerCase());
        continue;
      }
      final controller = _controllers.putIfAbsent(field.key, TextEditingController.new);
      controller.text = registration?.formData[field.key]?.toString() ?? '';
    }

    for (final field in detail.appellation.formSchema?.fields ?? const <AppellationFormField>[]) {
      if (field.type == 'criterion') {
        _checks[field.key] = true;
      }
    }

    setState(() {
      _detail = detail;
      _formUploads.clear();
      _removeFormFiles.clear();
      _legacyUploads.clear();
    });
  }

  Future<void> _pickFormFiles(String key) async {
    final files = await _pickUploads(allowMultiple: true);
    if (files.isEmpty) {
      return;
    }
    setState(() => _formUploads.putIfAbsent(key, () => []).addAll(files));
  }

  Future<void> _pickLegacyFile(String key) async {
    final files = await _pickUploads(allowMultiple: false);
    if (files.isEmpty) {
      return;
    }
    setState(() => _legacyUploads[key] = files.first);
  }

  Future<List<AppellationUpload>> _pickUploads({required bool allowMultiple}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
    if (result == null) {
      return const [];
    }
    final files = <AppellationUpload>[];
    for (final file in result.files) {
      if (file.bytes == null) continue;
      final compressed = await ImageCompressor.compressImage(
        fileName: file.name,
        bytes: file.bytes!,
      );
      files.add(AppellationUpload(name: compressed.name, bytes: compressed.bytes));
    }
    if (files.isEmpty) {
      setState(() => _errorMessage = 'Không đọc được file đã chọn.');
    }
    return files;
  }

  Future<void> _submit() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final form = <String, String>{};
    for (final field in detail.appellation.formSchema?.fields ?? const <AppellationFormField>[]) {
      if (field.key.isEmpty || field.type == 'section' || field.type == 'file') {
        continue;
      }
      if (field.type == 'checkbox' || field.type == 'criterion') {
        form[field.key] = (_checks[field.key] ?? field.type == 'criterion') ? '1' : '';
      } else {
        form[field.key] = _controllers[field.key]?.text.trim() ?? '';
      }
    }

    final payload = AppellationSubmitPayload(
      form: form,
      formFiles: _formUploads,
      removeFormFiles: _removeFormFiles,
      legacyFiles: _legacyUploads,
    );

    try {
      if (detail.registration == null) {
        await widget.service.register(appellationId: detail.appellation.id, payload: payload);
        setState(() => _successMessage = 'Đã đăng ký danh hiệu thành công.');
      } else {
        await widget.service.updateRegistration(registrationId: detail.registration!.id, payload: payload);
        setState(() => _successMessage = 'Đã cập nhật hồ sơ danh hiệu.');
      }
      final refreshed = await widget.service.fetchDetail(widget.appellationId);
      _applyDetail(refreshed);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không lưu được hồ sơ danh hiệu.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleRemove(String key, String path) {
    setState(() {
      final paths = _removeFormFiles.putIfAbsent(key, () => []);
      if (paths.contains(path)) {
        paths.remove(path);
      } else {
        paths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final registration = detail?.registration;
    final canSubmit = detail != null &&
        (registration == null ? detail.appellation.isOpen : registration.canEdit);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveBackground,
        surfaceTintColor: AppColors.adaptiveBackground,
        title: const Text('Chi tiết danh hiệu', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && detail == null
                ? _Message(message: _errorMessage!, isError: true)
                : detail == null
                    ? const _Message(message: 'Chưa có dữ liệu danh hiệu.', isError: false)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        children: [
                          _HeaderCard(item: detail.appellation, registration: registration),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _Banner(message: _errorMessage!, color: AppColors.danger),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 12),
                            _Banner(message: _successMessage!, color: const Color(0xFF059669)),
                          ],
                          const SizedBox(height: 16),
                          if (detail.appellation.formSchema == null)
                            _LegacyForm(
                              registration: registration,
                              canSubmit: canSubmit,
                              legacyUploads: _legacyUploads,
                              onPick: _pickLegacyFile,
                            )
                          else
                            _DynamicForm(
                              schema: detail.appellation.formSchema!,
                              registration: registration,
                              canSubmit: canSubmit,
                              controllers: _controllers,
                              checks: _checks,
                              uploads: _formUploads,
                              removeFormFiles: _removeFormFiles,
                              onPickFiles: _pickFormFiles,
                              onToggleCheck: (key, value) => setState(() => _checks[key] = value),
                              onToggleRemove: _toggleRemove,
                            ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: registration == null ? 'Đăng ký danh hiệu' : 'Lưu hồ sơ',
                            isLoading: _isSaving,
                            onPressed: canSubmit ? _submit : null,
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item, required this.registration});

  final AppellationItem item;
  final AppellationRegistration? registration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.name.isEmpty ? 'Danh hiệu' : item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (item.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.note, style: TextStyle(color: Colors.white.withValues(alpha: 0.84), height: 1.4)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LightBadge(label: '${compactDate(item.timeStart)} - ${compactDate(item.timeStop)}'),
              _LightBadge(label: item.isOpen ? 'Đang mở đăng ký' : 'Đã đóng đăng ký'),
              if (registration != null) _LightBadge(label: registration!.statusLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _DynamicForm extends StatelessWidget {
  const _DynamicForm({
    required this.schema,
    required this.registration,
    required this.canSubmit,
    required this.controllers,
    required this.checks,
    required this.uploads,
    required this.removeFormFiles,
    required this.onPickFiles,
    required this.onToggleCheck,
    required this.onToggleRemove,
  });

  final AppellationFormSchema schema;
  final AppellationRegistration? registration;
  final bool canSubmit;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checks;
  final Map<String, List<AppellationUpload>> uploads;
  final Map<String, List<String>> removeFormFiles;
  final ValueChanged<String> onPickFiles;
  final void Function(String key, bool value) onToggleCheck;
  final void Function(String key, String path) onToggleRemove;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu mẫu đăng ký',
            style: TextStyle(color: AppColors.adaptiveTextPrimary, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...schema.fields.map(
            (field) => _FormFieldBlock(
              field: field,
              canSubmit: canSubmit,
              controller: controllers[field.key],
              checked: checks[field.key] ?? field.type == 'criterion',
              existingFiles: registration?.formFiles[field.key] ?? const [],
              uploads: uploads[field.key] ?? const [],
              removedPaths: removeFormFiles[field.key] ?? const [],
              onPickFiles: () => onPickFiles(field.key),
              onToggleCheck: (value) => onToggleCheck(field.key, value),
              onToggleRemove: (path) => onToggleRemove(field.key, path),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormFieldBlock extends StatelessWidget {
  const _FormFieldBlock({
    required this.field,
    required this.canSubmit,
    required this.controller,
    required this.checked,
    required this.existingFiles,
    required this.uploads,
    required this.removedPaths,
    required this.onPickFiles,
    required this.onToggleCheck,
    required this.onToggleRemove,
  });

  final AppellationFormField field;
  final bool canSubmit;
  final TextEditingController? controller;
  final bool checked;
  final List<AppellationFile> existingFiles;
  final List<AppellationUpload> uploads;
  final List<String> removedPaths;
  final VoidCallback onPickFiles;
  final ValueChanged<bool> onToggleCheck;
  final ValueChanged<String> onToggleRemove;

  @override
  Widget build(BuildContext context) {
    if (field.type == 'section') {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          field.label,
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
        ),
      );
    }

    if (field.type == 'file' || field.type == 'criterion') {
      return _EvidenceField(
        field: field,
        canSubmit: canSubmit,
        checked: checked,
        existingFiles: existingFiles,
        uploads: uploads,
        removedPaths: removedPaths,
        onPickFiles: onPickFiles,
        onToggleCheck: onToggleCheck,
        onToggleRemove: onToggleRemove,
      );
    }

    if (field.type == 'checkbox') {
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: checked,
        onChanged: canSubmit ? (value) => onToggleCheck(value ?? false) : null,
        title: Text(field.required ? '${field.label} *' : field.label),
        subtitle: field.help.isEmpty ? null : Text(field.help),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: canSubmit && field.type != 'drl_latest_score',
        minLines: field.type == 'textarea' ? 3 : 1,
        maxLines: field.type == 'textarea' ? 5 : 1,
        keyboardType: field.type == 'number' || field.type == 'drl_latest_score'
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: field.type == 'number' ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          helperText: field.help.isEmpty ? null : field.help,
          prefixIcon: Icon(field.type == 'date' ? Icons.calendar_today_outlined : Icons.edit_note_outlined),
        ),
      ),
    );
  }
}

class _EvidenceField extends StatelessWidget {
  const _EvidenceField({
    required this.field,
    required this.canSubmit,
    required this.checked,
    required this.existingFiles,
    required this.uploads,
    required this.removedPaths,
    required this.onPickFiles,
    required this.onToggleCheck,
    required this.onToggleRemove,
  });

  final AppellationFormField field;
  final bool canSubmit;
  final bool checked;
  final List<AppellationFile> existingFiles;
  final List<AppellationUpload> uploads;
  final List<String> removedPaths;
  final VoidCallback onPickFiles;
  final ValueChanged<bool> onToggleCheck;
  final ValueChanged<String> onToggleRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.type == 'criterion')
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: checked,
              onChanged: canSubmit ? (value) => onToggleCheck(value ?? true) : null,
              title: Text(
                field.required ? '${field.label} *' : field.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: field.help.isEmpty ? null : Text(field.help),
            )
          else ...[
            Text(
              field.required ? '${field.label} *' : field.label,
              style: TextStyle(color: AppColors.adaptiveTextPrimary, fontWeight: FontWeight.w900),
            ),
            if (field.help.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(field.help, style: TextStyle(color: AppColors.adaptiveTextSecondary, height: 1.35)),
            ],
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Minh chứng', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              if (canSubmit && (field.type != 'criterion' || checked))
                TextButton.icon(
                  onPressed: onPickFiles,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Chọn file'),
                ),
            ],
          ),
          if (existingFiles.isEmpty && uploads.isEmpty)
            Text('Chưa có file.', style: TextStyle(color: AppColors.adaptiveTextSecondary)),
          ...existingFiles.map(
            (file) => _FileChip(
              label: file.name.isEmpty ? file.path : file.name,
              removed: removedPaths.contains(file.path),
              onRemove: canSubmit ? () => onToggleRemove(file.path) : null,
            ),
          ),
          ...uploads.map((file) => _FileChip(label: 'Mới: ${file.name}', removed: false)),
        ],
      ),
    );
  }
}

class _LegacyForm extends StatelessWidget {
  const _LegacyForm({
    required this.registration,
    required this.canSubmit,
    required this.legacyUploads,
    required this.onPick,
  });

  final AppellationRegistration? registration;
  final bool canSubmit;
  final Map<String, AppellationUpload> legacyUploads;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hồ sơ đăng ký',
            style: TextStyle(color: AppColors.adaptiveTextPrimary, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'Danh hiệu này chưa có form điện tử. Bạn có thể nộp bản khai và minh chứng như trên web.',
            style: TextStyle(color: AppColors.adaptiveTextSecondary, height: 1.35),
          ),
          const SizedBox(height: 14),
          _LegacyFileRow(
            title: 'Bản khai',
            current: registration?.file,
            upload: legacyUploads['file'],
            canSubmit: canSubmit,
            onPick: () => onPick('file'),
          ),
          _LegacyFileRow(
            title: 'Minh chứng',
            current: registration?.proof,
            upload: legacyUploads['proof'],
            canSubmit: canSubmit,
            onPick: () => onPick('proof'),
          ),
        ],
      ),
    );
  }
}

class _LegacyFileRow extends StatelessWidget {
  const _LegacyFileRow({
    required this.title,
    required this.current,
    required this.upload,
    required this.canSubmit,
    required this.onPick,
  });

  final String title;
  final AppellationFile? current;
  final AppellationUpload? upload;
  final bool canSubmit;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  upload?.name ?? current?.name ?? 'Chưa chọn file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.adaptiveTextSecondary),
                ),
              ],
            ),
          ),
          if (canSubmit)
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Chọn'),
            ),
        ],
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({
    required this.label,
    required this.removed,
    this.onRemove,
  });

  final String label;
  final bool removed;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: removed ? AppColors.danger.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            removed ? Icons.delete_outline_rounded : Icons.insert_drive_file_outlined,
            color: removed ? AppColors.danger : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              removed ? 'Sẽ xóa: $label' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: removed ? AppColors.danger : AppColors.adaptiveTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(removed ? Icons.undo_rounded : Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _LightBadge extends StatelessWidget {
  const _LightBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
