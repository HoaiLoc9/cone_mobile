import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AchievementStoryModal extends StatelessWidget {
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

  Color _getClassificationColor(String rank) {
    final lower = rank.toLowerCase();
    if (lower.contains('xuất sắc')) return const Color(0xFFF59E0B);
    if (lower.contains('tốt')) return const Color(0xFF10B981);
    if (lower.contains('khá')) return const Color(0xFF3B82F6);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getClassificationColor(rankLabel);
    final scoreStr = totalScore.toStringAsFixed(
      totalScore.truncateToDouble() == totalScore ? 0 : 1,
    );

    final shareText =
        '🏆 THÀNH TÍCH ĐIỂM RÈN LUYỆN - CONE 🏆\n'
        'Sinh viên: ${studentName.toUpperCase()} ($studentCode)\n'
        'Lớp: $studentClass\n'
        'Học kỳ: $semesterName\n'
        'Điểm rèn luyện: $scoreStr / 100\n'
        'Xếp loại: ${rankLabel.toUpperCase()}\n'
        'Hoạt động đã tham gia: $activityCount\n'
        'Tự hào rèn luyện & phát triển toàn diện cùng COne!';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              const SizedBox(height: 18),

              // Card Story 9:16
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      blurRadius: 30,
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
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'COne • BẢNG VÀNG RÈN LUYỆN',
                          style: TextStyle(
                            color: Color(0xFFFCD34D),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Avatar & Tên
                    Text(
                      studentName.isEmpty ? 'SINH VIÊN CONE' : studentName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MSSV: $studentCode • $studentClass',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Vòng tròn điểm số tỏa sáng
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            rankColor.withValues(alpha: 0.25),
                            rankColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: rankColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            scoreStr,
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/ 100 ĐIỂM',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Badge Xếp loại
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: rankColor.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: Text(
                        'XẾP LOẠI: ${rankLabel.toUpperCase()}',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Học kỳ & Số hoạt động
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Học kỳ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                semesterName.isNotEmpty ? semesterName : 'HK Hiện tại',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
                          Column(
                            children: [
                              Text(
                                'Hoạt động tham gia',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$activityCount hoạt động',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: shareText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép tóm tắt thành tích để chia sẻ Story/Mạng xã hội! 🎉'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Sao chép Story',
                        style: TextStyle(fontWeight: FontWeight.w900),
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
}
