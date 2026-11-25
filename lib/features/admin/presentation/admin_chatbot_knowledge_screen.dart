import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/locale_service.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/admin_service.dart';

/// Màn hình Quản lý & Train tài liệu cho AI Chatbot (đồng bộ kho tri thức RAG với Web)
class AdminChatbotKnowledgeScreen extends StatefulWidget {
  const AdminChatbotKnowledgeScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminChatbotKnowledgeScreen> createState() =>
      _AdminChatbotKnowledgeScreenState();
}

class _AdminChatbotKnowledgeScreenState
    extends State<AdminChatbotKnowledgeScreen> {
  late Future<List<ChatbotKnowledgeDoc>> _future =
      widget.service.chatbotDocuments();
  bool _isUploading = false;
  String? _uploadingFileName;

  void _reload() {
    setState(() {
      _future = widget.service.chatbotDocuments();
    });
  }

  Future<void> _pickAndTrainDocument() async {
    if (_isUploading) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'txt', 'md'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'Không đọc được nội dung file đã chọn.',
                'Unable to read selected file.',
              ),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (bytes.length > 25 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'File vượt quá 25MB. Vui lòng chọn tài liệu nhỏ hơn.',
                'File exceeds 25MB limit.',
              ),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadingFileName = file.name;
      });

      final msg = await widget.service.uploadChatbotDocument(
        filename: file.name,
        base64Content: base64Encode(bytes),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Lỗi khi train tài liệu: $e', 'Training failed: $e'),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingFileName = null;
        });
      }
    }
  }

  Future<void> _confirmDelete(ChatbotKnowledgeDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('Gỡ tài liệu khỏi AI?', 'Remove from AI knowledge?'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        content: Text(
          tr(
            'Tài liệu "${doc.name}" và các đoạn vector liên quan sẽ bị xóa khỏi kho tri thức chung (Web & App).',
            '"${doc.name}" and its vector embeddings will be removed from both Web & Mobile AI.',
          ),
          style: TextStyle(color: AppColors.adaptiveTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Gỡ tài liệu', 'Remove')),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final msg = await widget.service.deleteChatbotDocument(
        sourceKey: doc.sourceKey,
        filename: doc.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Không thể gỡ tài liệu.', 'Unable to remove file.')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  IconData _iconForExt(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
      return Icons.description_rounded;
    }
    return Icons.article_rounded;
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
          tr('Kho tri thức & Train AI', 'AI Knowledge & Training'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr('Làm mới', 'Refresh'),
            onPressed: _reload,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.adaptiveTextPrimary,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndTrainDocument,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(
          _isUploading
              ? tr('Đang train AI...', 'Training AI...')
              : tr('Nạp tài liệu mới', 'Train New File'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // Hero giới thiệu đồng bộ Web & App
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'Đồng bộ tri thức Web & App',
                              'Synced Web & App AI Brain',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'Tài liệu PDF, DOCX, TXT, MD nạp tại đây sẽ được xử lý vào kho tri thức chung (RAG/BM25) để Chatbot trên cả Web và App Mobile cùng trả lời ngay.',
                              'PDF, DOCX, TXT, MD files uploaded here are indexed into the shared AI knowledge base (RAG/BM25) for both Web & Mobile Chatbots.',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_isUploading) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr(
                                'Đang phân tích & nhúng vector: ${_uploadingFileName ?? ''}',
                                'Embedding document: ${_uploadingFileName ?? ''}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.primary,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              FutureBuilder<List<ChatbotKnowledgeDoc>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerListLoading(itemCount: 4);
                  }
                  if (snapshot.hasError) {
                    return AppErrorView.fromError(
                      snapshot.error,
                      fallbackTitle: tr(
                        'Chưa tải được danh sách tài liệu AI',
                        'Unable to load AI documents',
                      ),
                      onRetry: _reload,
                    );
                  }

                  final docs = snapshot.data ?? const [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 38,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.adaptiveBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 44,
                            color: AppColors.adaptiveTextSecondary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tr(
                              'Chưa có tài liệu tri thức nào',
                              'No trained documents yet',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'Bấm "Nạp tài liệu mới" bên dưới để train quy chế, hướng dẫn cho AI Chatbot.',
                              'Tap "Train New File" below to upload guidelines for the AI Chatbot.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.adaptiveTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          'Tài liệu đã train (${docs.length})',
                          'Trained Documents (${docs.length})',
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final doc in docs)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.adaptiveCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.adaptiveBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconForExt(doc.name),
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.adaptiveTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      doc.formattedSize.isNotEmpty
                                          ? '${doc.source} • ${doc.formattedSize}'
                                          : doc.source,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.adaptiveTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: tr('Gỡ tài liệu', 'Remove'),
                                onPressed: () => _confirmDelete(doc),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
