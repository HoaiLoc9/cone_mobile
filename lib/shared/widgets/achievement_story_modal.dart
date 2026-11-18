import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/config/app_colors.dart';

class AchievementStoryModal extends StatefulWidget {
  const AchievementStoryModal({
    super.key,
    required this.studentName,
    required this.studentCode,
    required this.studentClass,
    required this.totalScore,
    required this.rankLabel,
    required this.semesterName,
    required this.activityCount,
  });

  final String studentName;
  final String studentCode;
  final String studentClass;
  final double totalScore;
  final String rankLabel;
  final String semesterName;
  final int activityCount;

  static void show(
    BuildContext context, {
    required String studentName,
    required String studentCode,
    required String studentClass,
    required double totalScore,
    required String rankLabel,
    required String semesterName,
    required int activityCount,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementStoryModal(
        studentName: studentName,
        studentCode: studentCode,
        studentClass: studentClass,
        totalScore: totalScore,
        rankLabel: rankLabel,
        semesterName: semesterName,
        activityCount: activityCount,
      ),
    );
  }

  @override
  State<AchievementStoryModal> createState() => _AchievementStoryModalState();
}

class _AchievementStoryModalState extends State<AchievementStoryModal> {
  final GlobalKey _storyCardKey = GlobalKey();
  bool _isSharing = false;

  Color _getClassificationColor(String rank) {
    final lower = rank.toLowerCase();
    if (lower.contains('xuất sắc')) return const Color(0xFF10B981);
    if (lower.contains('tốt')) return const Color(0xFF38BDF8);
    if (lower.contains('khá')) return const Color(0xFF60A5FA);
    return const Color(0xFF94A3B8);
  }

  String get _scoreStr => widget.totalScore.toStringAsFixed(
        widget.totalScore.truncateToDouble() == widget.totalScore ? 0 : 1,
      );

  String get _shareText =>
      '🏆 THÀNH TÍCH ĐIỂM RÈN LUYỆN - CONE 🏆\n'
      'Sinh viên: ${widget.studentName.toUpperCase()} (${widget.studentCode})\n'
      'Lớp: ${widget.studentClass}\n'
      'Học kỳ: ${widget.semesterName}\n'
      'Điểm rèn luyện: $_scoreStr / 100\n'
      'Xếp loại: ${widget.rankLabel.toUpperCase()}\n'
      'Hoạt động đã tham gia: ${widget.activityCount}\n'
      '#COne #COFER #DiemRenLuyen';

  Future<Uint8List?> _captureStoryPng() async {
    try {
      final boundary =
          _storyCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _buildStoryPdfBytes(Uint8List? pngBytes) async {
    final doc = pw.Document();
    if (pngBytes != null) {
      final img = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(380, 620, marginAll: 12),
          build: (_) => pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ),
      );
    } else {
      final font = await PdfGoogleFonts.robotoBold();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (_) => pw.Center(
            child: pw.Text(
              _shareText,
              style: pw.TextStyle(font: font, fontSize: 14),
            ),
          ),
        ),
      );
    }
    return doc.save();
  }

  Future<void> _copyStoryToClipboard({String? platformName}) async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          platformName != null
              ? 'Đã sao chép nội dung Story! Đang mở chia sẻ qua $platformName...'
              : 'Đã sao chép tóm tắt thành tích vào bộ nhớ tạm! 🎉',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareToSocialApp(String platformName) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Clipboard.setData(ClipboardData(text: _shareText));
      final pngBytes = await _captureStoryPng();
      final pdfBytes = await _buildStoryPdfBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã sao chép caption Story và chuẩn bị thẻ thành tích chia sẻ lên $platformName!',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final safeCode = widget.studentCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'COne_Story_${safeCode}_${platformName.toLowerCase()}.pdf',
        subject: 'Thành tích Điểm Rèn Luyện COne - ${widget.studentName}',
        body: _shareText,
      );
    } catch (_) {
      if (mounted) {
        _showSocialShareFallbackSheet(platformName);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showSocialShareFallbackSheet(String platformName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.adaptiveCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chia sẻ lên $platformName',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nội dung thành tích của bạn đã được tự động sao chép vào Clipboard. Bạn có thể dán trực tiếp lên bài viết hoặc Story $platformName:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.adaptiveTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.adaptiveCardSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.adaptiveBorder),
              ),
              child: SelectableText(
                _shareText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adaptiveTextPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _shareText));
              Navigator.of(dialogCtx).pop();
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getClassificationColor(widget.rankLabel);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo gạt
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Story 9:16 bọc trong RepaintBoundary để xuất hình/PDF chia sẻ MXH
              RepaintBoundary(
                key: _storyCardKey,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E3A8A),
                        Color(0xFF1D4ED8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF93C5FD),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'COne • BẢNG VÀNG RÈN LUYỆN',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tên & MSSV
                      Text(
                        widget.studentName.isEmpty
                            ? 'SINH VIÊN CONE'
                            : widget.studentName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MSSV: ${widget.studentCode} • ${widget.studentClass}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Vòng tròn điểm số tỏa sáng
                      Container(
                        width: 122,
                        height: 122,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              rankColor.withValues(alpha: 0.25),
                              rankColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: rankColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: rankColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _scoreStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '/ 100 ĐIỂM',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Badge Xếp loại
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: rankColor.withValues(alpha: 0.65),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'XẾP LOẠI: ${widget.rankLabel.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Học kỳ & Số hoạt động
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Học kỳ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.semesterName.isNotEmpty
                                      ? widget.semesterName
                                      : 'HK Hiện tại',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 26,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Hoạt động tham gia',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.activityCount} hoạt động',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Hàng chọn ứng dụng Mạng Xã Hội để chia sẻ nhanh
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CHIA SẺ NHANH QUA MẠNG XÃ HỘI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSocialButton(
                      label: 'Facebook',
                      icon: Icons.facebook_rounded,
                      color: const Color(0xFF1877F2),
                      onTap: () => _shareToSocialApp('Facebook'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      label: 'Zalo',
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF0068FF),
                      onTap: () => _shareToSocialApp('Zalo'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      label: 'Instagram',
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: () => _shareToSocialApp('Instagram'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      label: 'Messenger',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: () => _shareToSocialApp('Messenger'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      label: 'Telegram',
                      icon: Icons.send_rounded,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _shareToSocialApp('Telegram'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      label: 'App khác',
                      icon: Icons.ios_share_rounded,
                      color: const Color(0xFF334155),
                      onTap: () => _shareToSocialApp('Ứng dụng khác'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons: Đóng | Sao chép Story | Chia sẻ MXH
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _copyStoryToClipboard(),
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: const Text(
                        'Sao chép Story',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSharing
                          ? null
                          : () => _shareToSocialApp('Mạng xã hội'),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 17),
                      label: const Text(
                        'Chia sẻ MXH',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
