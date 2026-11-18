import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../data/student_services_service.dart';
import 'student_service_screens.dart';

class OtherServicesScreen extends StatelessWidget {
  const OtherServicesScreen({super.key, required this.service});

  final StudentServicesService service;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          'Dịch vụ & Tiện ích khác',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.adaptiveTextPrimary),
        ),
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          children: [
            // Banner giới thiệu
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.amberAccent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cổng Tiện ích Sinh viên',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Hồ sơ hành chính, tài liệu quy chế & hỗ trợ học vụ',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nhóm 1: THỦ TỤC & HÀNH CHÍNH
            _buildSectionHeader('THỦ TỤC & HÀNH CHÍNH', Icons.assignment_outlined),
            const SizedBox(height: 12),
            _buildServiceItem(
              icon: Icons.assignment_turned_in_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Giấy xin phép',
              subtitle: 'Xin vắng hoạt động, bù hoạt động, xin miễn rèn luyện',
              badge: 'HÀNH CHÍNH',
              onTap: () => _push(context, PermissionRequestsScreen(service: service)),
            ),
            const SizedBox(height: 12),
            _buildServiceItem(
              icon: Icons.draw_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Chữ ký số',
              subtitle: 'Ký số văn bản điện tử, biên bản cam kết rèn luyện',
              onTap: () => _push(context, SignatureRequestsScreen(service: service)),
            ),
            const SizedBox(height: 12),
            _buildServiceItem(
              icon: Icons.verified_user_rounded,
              iconColor: const Color(0xFF0D9488),
              title: 'Kiểm tra hồ sơ sinh viên',
              subtitle: 'Xem mức độ hoàn thiện thông tin cá nhân & lý lịch',
              onTap: () => _push(context, ProfileStatusScreen(service: service)),
            ),
            const SizedBox(height: 26),

            // Nhóm 2: HỒ SƠ & TÀI LIỆU RÈN LUYỆN
            _buildSectionHeader('HỒ SƠ & TÀI LIỆU', Icons.folder_open_rounded),
            const SizedBox(height: 12),
            _buildServiceItem(
              icon: Icons.folder_copy_rounded,
              iconColor: const Color(0xFF0284C7),
              title: 'Tài liệu & Quy chế',
              subtitle: 'Biểu mẫu rèn luyện, quyết định, quy chế sinh viên COFER',
              onTap: () => _push(context, DocumentsScreen(service: service)),
            ),
            const SizedBox(height: 12),
            _buildServiceItem(
              icon: Icons.badge_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'CV sinh viên & Năng lực',
              subtitle: 'Tạo và xuất hồ sơ năng lực thành tích rèn luyện ngoại khóa',
              badge: 'CV PRO',
              onTap: () => _push(context, CvScreen(service: service)),
            ),
            const SizedBox(height: 26),

            // Nhóm 3: THÔNG TIN HỖ TRỢ CTSV
            _buildSectionHeader('HỖ TRỢ SINH VIÊN', Icons.support_agent_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Phòng Công tác Sinh viên (CTSV)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildContactRow(
                    Icons.location_on_outlined,
                    'Cơ sở 1: 287 Phan Đình Phùng, P.15, Q. Phú Nhuận, TP.HCM',
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.location_on_outlined,
                    'Cơ sở 2: 12 Nguyễn Văn Bảo, P.4, Q. Gò Vấp, TP.HCM',
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.phone_in_talk_outlined,
                    'Hotline: (028) 3844 6320 • (028) 3845 7440',
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.mail_outline_rounded,
                    'Email: ctsv@cofer.edu.vn • ctsv.cofer@gmail.com',
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.access_time_rounded,
                    'Giờ làm việc: Thứ 2 - Thứ 6 (7h30 - 11h30 | 13h00 - 17h00)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Nhóm 4: HỎI ĐÁP & QUY ĐỊNH RÈN LUYỆN
            _buildSectionHeader('HỎI ĐÁP THƯỜNG GẶP (FAQ)', Icons.help_outline_rounded),
            const SizedBox(height: 12),
            _buildFaqTile(
              question: 'Khi nào hệ thống chốt Điểm rèn luyện học kỳ?',
              answer:
                  'Hệ thống mở cổng tự đánh giá từ tuần 14 đến tuần 16 của học kỳ. Sau đó GVCN và Khoa sẽ duyệt điểm trong vòng 2 tuần trước khi có quyết định công nhận điểm chính thức từ Hiệu trưởng.',
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              question: 'Nếu tham gia hoạt động nhưng chưa được điểm danh thì sao?',
              answer:
                  'Bạn hãy vào mục "Minh chứng" trên Trang chủ, tìm hoạt động đó và bấm "Gửi minh chứng" kèm ảnh chụp tại sự kiện để Ban tổ chức kiểm tra và cộng điểm bù.',
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              question: 'Tiêu chuẩn xếp loại điểm rèn luyện như thế nào?',
              answer:
                  '• Xuất sắc: 90 - 100 điểm\n• Tốt: 80 - 89 điểm\n• Khá: 65 - 79 điểm\n• Trung bình: 50 - 64 điểm\n• Yếu: 35 - 49 điểm\n• Kém: dưới 35 điểm.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
