import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../auth/data/student_user.dart';
import 'drl_models.dart';

class DrlPdfService {
  DrlPdfService._();

  /// Tạo tài liệu PDF Bảng điểm rèn luyện chính thức có hỗ trợ tiếng Việt Unicode
  static Future<Uint8List> generateDrlPdf({
    required DrlDetail detail,
    required StudentUser student,
  }) async {
    final pdf = pw.Document();

    // Tải font Unicode tiếng Việt (Roboto) từ Google Fonts
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final criteria = detail.criteriaScore;
    final semester = detail.semester;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return [
            // Tiêu đề đầu trang chuẩn văn bản
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'BỘ CÔNG THƯƠNG',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      'TRƯỜNG CĐ KINH TẾ ĐỐI NGOẠI',
                      style: pw.TextStyle(font: boldFont, fontSize: 11),
                    ),
                    pw.Container(
                      height: 1,
                      width: 120,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(top: 2),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.Text(
                      'Độc lập - Tự do - Hạnh phúc',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.Container(
                      height: 1,
                      width: 140,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(top: 2),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Tên tài liệu
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'PHIẾU ĐÁNH GIÁ ĐIỂM RÈN LUYỆN SINH VIÊN',
                    style: pw.TextStyle(font: boldFont, fontSize: 15, color: PdfColors.blue800),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Học kỳ: ${semester.name}',
                    style: pw.TextStyle(font: italicFont, fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Thông tin sinh viên
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Họ và tên: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                              pw.TextSpan(text: student.name, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Mã số SV: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                              pw.TextSpan(text: student.code, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Lớp: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                              pw.TextSpan(text: student.studentClass, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Khoa: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                              pw.TextSpan(text: student.department, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Bảng điểm chi tiết 5 tiêu chí
            pw.Text(
              'I. BẢNG TỔNG HỢP TIÊU CHÍ ĐÁNH GIÁ',
              style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(font: regularFont, fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['STT', 'Nội dung tiêu chí đánh giá', 'Tối đa', 'SV chấm', 'Lớp chấm', 'GVCN'],
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FixedColumnWidth(48),
                3: const pw.FixedColumnWidth(48),
                4: const pw.FixedColumnWidth(52),
                5: const pw.FixedColumnWidth(48),
              },
              data: [
                for (int i = 0; i < criteria.sections.length; i++) ...[
                  [
                    '${i + 1}',
                    'Tiêu chí ${criteria.sections[i].section}',
                    '-',
                    criteria.sections[i].capped.toStringAsFixed(1),
                    criteria.sections[i].classCapped.toStringAsFixed(1),
                    criteria.sections[i].advisorCapped.toStringAsFixed(1),
                  ],
                ],
                [
                  '',
                  'TỔNG ĐIỂM RÈN LUYỆN',
                  '100 đ',
                  criteria.studentTotal.toStringAsFixed(1),
                  criteria.classTotal.toStringAsFixed(1),
                  criteria.advisorTotal.toStringAsFixed(1),
                ],
                [
                  '',
                  'XẾP LOẠI RÈN LUYỆN',
                  '',
                  criteria.studentClassification,
                  criteria.classClassification,
                  criteria.advisorClassification,
                ],
              ],
            ),
            pw.SizedBox(height: 18),

            // Điểm tổng kết nổi bật
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.blue50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'KẾT QUẢ ĐRL CHÍNH THỨC:',
                    style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.blue900),
                  ),
                  pw.Text(
                    '${criteria.advisorTotal > 0 ? criteria.advisorTotal.toStringAsFixed(1) : criteria.studentTotal.toStringAsFixed(1)} điểm  -  Xếp loại: ${criteria.advisorClassification.isNotEmpty ? criteria.advisorClassification : criteria.studentClassification}',
                    style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.red800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),

            // Phần ký tên xác nhận 4 bên
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    pw.Text('SINH VIÊN', style: pw.TextStyle(font: boldFont, fontSize: 9.5)),
                    pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(font: italicFont, fontSize: 8)),
                    pw.SizedBox(height: 45),
                    pw.Text(student.name, style: pw.TextStyle(font: boldFont, fontSize: 9.5)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('BAN CÁN SỰ LỚP', style: pw.TextStyle(font: boldFont, fontSize: 9.5)),
                    pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(font: italicFont, fontSize: 8)),
                    pw.SizedBox(height: 45),
                    pw.Text('Xác nhận của BCS', style: pw.TextStyle(font: regularFont, fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('GIÁO VIÊN CHỦ NHIỆM', style: pw.TextStyle(font: boldFont, fontSize: 9.5)),
                    pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(font: italicFont, fontSize: 8)),
                    pw.SizedBox(height: 45),
                    pw.Text('Phê duyệt GVCN', style: pw.TextStyle(font: regularFont, fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('BAN GIÁM HIỆU / KHOA', style: pw.TextStyle(font: boldFont, fontSize: 9.5)),
                    pw.Text('(Ký tên và đóng dấu)', style: pw.TextStyle(font: italicFont, fontSize: 8)),
                    pw.SizedBox(height: 45),
                    pw.Text('Duyệt kết quả', style: pw.TextStyle(font: regularFont, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Mở giao diện xem trước (preview), in trực tiếp hoặc lưu file PDF
  static Future<void> printOrShare({
    required DrlDetail detail,
    required StudentUser student,
  }) async {
    final pdfBytes = await generateDrlPdf(detail: detail, student: student);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Phieu_DRL_${student.code}_${detail.semester.id}.pdf',
    );
  }
}
