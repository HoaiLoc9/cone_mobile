import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


import '../../auth/data/student_user.dart';
import 'drl_models.dart';

class DrlPdfExporter {
  static String _rankLabel(double score) {
    if (score >= 90) return 'Xuất sắc';
    if (score >= 80) return 'Tốt';
    if (score >= 65) return 'Khá';
    if (score >= 50) return 'Trung bình';
    if (score >= 35) return 'Yếu';
    return 'Kém';
  }

  static String _fmtScore(double score) {
    return score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
  }

  static Future<Uint8List> buildTranscriptPdf({
    required DrlSummary summary,
    StudentUser? user,
  }) async {
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final studentName = (user?.name.isNotEmpty == true) ? user!.name : 'Sinh viên COFER';
    final studentCode = (user?.code.isNotEmpty == true) ? user!.code : '-';
    final studentClass = (user?.studentClass.isNotEmpty == true) ? user!.studentClass : '-';
    final department = (user?.department.isNotEmpty == true) ? user!.department : '-';

    final primaryBlue = PdfColor.fromInt(0xFF1E3A8A);
    final softBg = PdfColor.fromInt(0xFFF1F5F9);
    final borderGrey = PdfColor.fromInt(0xFFCBD5E1);
    final mutedText = PdfColor.fromInt(0xFF475569);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Quốc hiệu / Tiêu đề trường
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BỘ CÔNG THƯƠNG',
                    style: pw.TextStyle(fontSize: 10, color: mutedText),
                  ),
                  pw.Text(
                    'TRƯỜNG CAO ĐẲNG KINH TẾ ĐỐI NGOẠI',
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'HỆ THỐNG CONE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  pw.Text(
                    'Ngày xuất: $dateStr',
                    style: pw.TextStyle(fontSize: 9.5, color: mutedText),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Center(
            child: pw.Text(
              'BẢNG TỔNG HỢP ĐIỂM RÈN LUYỆN SINH VIÊN',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Khối thông tin sinh viên
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: softBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderGrey),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _kv('Họ và tên:', studentName),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _kv('Mã số sinh viên:', studentCode),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _kv('Lớp sinh hoạt:', studentClass),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _kv('Khoa / Đơn vị:', department),
                    ),
                  ],
                ),
                pw.Divider(color: borderGrey, height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _kv('Điểm rèn luyện tổng kết:', '${_fmtScore(summary.totalPoints)} / 100 điểm'),
                    _kv('Xếp loại:', _rankLabel(summary.totalPoints)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Bảng chi tiết các học kỳ
          pw.Text(
            'Chi tiết điểm rèn luyện theo học kỳ',
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          pw.SizedBox(height: 8),

          if (summary.semesterSummaries.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Chưa có dữ liệu điểm rèn luyện theo học kỳ.',
                style: pw.TextStyle(fontSize: 11, color: mutedText),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderGrey, width: 0.7),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10.5,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryBlue),
              cellStyle: const pw.TextStyle(fontSize: 10.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
              headers: ['STT', 'Học kỳ', 'Số hoạt động', 'Điểm ĐRL', 'Xếp loại'],
              data: List.generate(summary.semesterSummaries.length, (i) {
                final s = summary.semesterSummaries[i];
                return [
                  '${i + 1}',
                  s.semesterName,
                  '${s.activityCount}',
                  '${_fmtScore(s.totalPoints)} / 100',
                  _rankLabel(s.totalPoints),
                ];
              }),
            ),

          pw.SizedBox(height: 22),
          pw.Text(
            'Ghi chú: Bảng điểm được trích xuất trực tiếp từ Hệ thống Quản lý Điểm rèn luyện sinh viên COne (COFER) phục vụ tra cứu và lưu trữ hồ sơ cá nhân.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: mutedText,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _kv(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
              fontSize: 10.5,
              color: PdfColor.fromInt(0xFF475569),
            ),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> exportAndShare({
    required DrlSummary summary,
    StudentUser? user,
  }) async {
    final bytes = await buildTranscriptPdf(summary: summary, user: user);
    final safeCode = (user?.code ?? 'SV').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'BangDiem_DRL_$safeCode.pdf',
      subject: 'Bảng điểm rèn luyện sinh viên - $safeCode',
    );
  }
}
