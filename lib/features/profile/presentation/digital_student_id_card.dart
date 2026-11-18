import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../../core/config/app_colors.dart';
import '../data/profile_models.dart';

/// Modal hiển thị Thẻ sinh viên điện tử (Digital Student ID Card) với hiệu ứng 3D lật thẻ
class DigitalStudentIdCardModal extends StatefulWidget {
  const DigitalStudentIdCardModal({super.key, required this.user});

  final ProfileUser user;

  static Future<void> show(BuildContext context, ProfileUser user) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DigitalStudentIdCardModal(user: user),
    );
  }

  @override
  State<DigitalStudentIdCardModal> createState() =>
      _DigitalStudentIdCardModalState();
}

class _DigitalStudentIdCardModalState extends State<DigitalStudentIdCardModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  bool _showBack = false;
  int _qrRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCardFlip() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _refreshQr() {
    setState(() {
      _qrRefreshKey = DateTime.now().millisecondsSinceEpoch;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm mới mã QR thẻ sinh viên'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = AppColors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.adaptiveBorder, width: 1.2)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thẻ Sinh Viên Điện Tử',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.adaptiveTextPrimary,
                          ),
                        ),
                        Text(
                          'Chạm vào thẻ để lật mặt sau',
                          style: TextStyle(fontSize: 12, color: AppColors.adaptiveTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.adaptiveTextSecondary),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated Flip Card
            GestureDetector(
              onTap: _toggleCardFlip,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * math.pi;
                  final isUnder = angle > math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D perspective
                      ..rotateY(angle),
                    child: isUnder
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(user),
                          )
                        : _buildCardFront(user),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Bottom Actions: Lật thẻ & Làm mới QR
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: AppColors.adaptiveBorder),
                    ),
                    onPressed: _toggleCardFlip,
                    icon: const Icon(Icons.flip_rounded, size: 18),
                    label: Text(_showBack ? 'Xem mặt trước' : 'Lật mặt sau'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _refreshQr,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Làm mới QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mặt trước thẻ sinh viên số
  Widget _buildCardFront(ProfileUser user) {
    final qrData = 'CONE_STUDENT:${user.code}:${user.name}:$_qrRefreshKey';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header trường & Chip thông minh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐẠI HỌC KINH TẾ - ĐỐI NGOẠI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'THẺ SINH VIÊN ĐIỆN TỬ (DIGITAL ID)',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Golden EMV Chip
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFFFF7C2), width: 0.8),
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26, width: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thông tin sinh viên & Mã QR
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user.avatarUrl.isNotEmpty
                      ? Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 40,
                          ),
                        )
                      : const Icon(Icons.person_rounded, color: Colors.white70, size: 40),
                ),
              ),
              const SizedBox(width: 14),

              // Tên & MSSV
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MSSV: ${user.code}',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lớp: ${user.studentClass.isNotEmpty ? user.studentClass : "-"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.department.isNotEmpty ? user.department : "Khoa CNTT",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code Box
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: CustomPaint(
                  painter: _QrPainter(
                    data: qrData,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barcode dải kẻ dưới đáy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 18),
                    painter: _BarcodePainter(seed: user.code),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ĐANG HỌC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mặt sau thẻ sinh viên số
  Widget _buildCardBack(ProfileUser user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          // Dải từ tính đen (Magnetic Stripe)
          Container(
            width: double.infinity,
            height: 38,
            color: Colors.black,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  'COne PASS #${user.code}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUY ĐỊNH SỬ DỤNG THẺ',
                          style: TextStyle(
                            color: const Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '1. Thẻ này là tài sản của Nhà trường, chứng nhận tư cách sinh viên.\n'
                          '2. Sử dụng khi điểm danh hoạt động, ra vào thư viện và phòng thi.\n'
                          '3. Không cho người khác mượn hoặc chỉnh sửa dữ liệu thẻ.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                    // Con dấu số
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'ĐÃ XÁC\nTHỰC',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hỗ trợ: support@cone.edu.vn',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9.5,
                      ),
                    ),
                    Text(
                      'Hotline: (028) 3822 5555',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Painter vẽ mã QR từ dữ liệu sinh viên
class _QrPainter extends CustomPainter {
  _QrPainter({required this.data, required this.color});

  final String data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      final count = qrImage.moduleCount;
      final pixelSize = size.width / count;
      final paint = Paint()..color = color;

      for (int x = 0; x < count; x++) {
        for (int y = 0; y < count; y++) {
          if (qrImage.isDark(y, x)) {
            final rect = Rect.fromLTWH(
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(pixelSize * 0.2)),
              paint,
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// Painter vẽ dải mã vạch Barcode mô phỏng
class _BarcodePainter extends CustomPainter {
  _BarcodePainter({required this.seed});

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.square;

    final hash = seed.hashCode;
    double currentX = 0;
    int idx = 0;

    while (currentX < size.width) {
      final barWidth = ((hash >> (idx % 16)) & 0x3) + 1.2;
      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX, size.height),
        paint,
      );
      currentX += barWidth + ((idx % 3 == 0) ? 3.0 : 1.5);
      idx++;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
