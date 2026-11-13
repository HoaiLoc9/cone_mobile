import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

class CuteAiRobotWidget extends StatefulWidget {
  const CuteAiRobotWidget({
    super.key,
    required this.onTap,
    this.greetingText = 'Hỏi tớ nhé! ✨',
  });

  final VoidCallback onTap;
  final String greetingText;

  @override
  State<CuteAiRobotWidget> createState() => _CuteAiRobotWidgetState();
}

class _CuteAiRobotWidgetState extends State<CuteAiRobotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _tiltAnimation;

  late final AnimationController _blinkController;
  late final Animation<double> _eyeHeightAnimation;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  bool _showBubble = true;

  @override
  void initState() {
    super.initState();

    // 1. Chuyển động lơ lửng hình sin lên xuống (Floating)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _tiltAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 2. Chuyển động chớp mắt ngẫu nhiên (Blinking)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _blinkController.reset();
          _blinkController.forward();
        }
      });

    _eyeHeightAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 90),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
    ]).animate(_blinkController);

    _blinkController.forward();

    // 3. Tay vẫy chào nhịp nhàng (Waving)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: -0.2, end: 0.35).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _blinkController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatingController,
          _blinkController,
          _waveController,
        ]),
        builder: (context, child) {
          final floatOffset = _floatingAnimation.value;
          final tilt = _tiltAnimation.value;
          final eyeScaleY = _eyeHeightAnimation.value;
          final waveAngle = _waveAnimation.value;

          // Tính độ co giãn của bóng đổ dưới chân theo độ cao của robot
          final shadowScale = 1.0 - (floatOffset.abs() / 30);
          final shadowOpacity = (0.28 - (floatOffset.abs() / 80)).clamp(0.08, 0.28);

          return SizedBox(
            width: 110,
            height: 125,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // 1. Bóng đổ 3D mặt đất co giãn theo nhịp bay
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 52 * shadowScale,
                    height: 12 * shadowScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: shadowOpacity),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Chú Robot 3D đang lơ lửng
                Positioned(
                  bottom: 12 + (-floatOffset),
                  child: Transform.rotate(
                    angle: tilt,
                    child: SizedBox(
                      width: 78,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Ăng-ten lắc lư trên đỉnh đầu
                          Positioned(
                            top: -14,
                            child: Column(
                              children: [
                                // Viên ngọc LED phát sáng
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF67E8F9),
                                        Color(0xFF06B6D4),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF06B6D4)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 3.5,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF94A3B8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tai trái (Headphone 3D)
                          Positioned(
                            left: -4,
                            top: 24,
                            child: Container(
                              width: 9,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(-2, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tai phải (Headphone 3D)
                          Positioned(
                            right: -4,
                            top: 24,
                            child: Container(
                              width: 9,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(2, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Thân đầu chính dạng Squircle Ngọc Trai 3D
                          Container(
                            width: 72,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF1F5F9),
                                  Color(0xFFE2E8F0),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Màn hình kính Visor mặt robot
                                Container(
                                  width: 56,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF090D16),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFF1E293B),
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Ánh phản chiếu kính visor chéo
                                      Positioned(
                                        top: 3,
                                        left: 6,
                                        child: Transform.rotate(
                                          angle: -0.4,
                                          child: Container(
                                            width: 20,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Hai mắt LED Neon xanh biết chớp
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildEye(eyeScaleY),
                                          const SizedBox(width: 14),
                                          _buildEye(eyeScaleY),
                                        ],
                                      ),

                                      // Má hồng cute
                                      Positioned(
                                        bottom: 5,
                                        left: 8,
                                        child: Container(
                                          width: 6,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 5,
                                        right: 8,
                                        child: Container(
                                          width: 6,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tay phải vẫy vẫy chào
                          Positioned(
                            right: -10,
                            top: 32,
                            child: Transform.rotate(
                              angle: waveAngle,
                              alignment: Alignment.topLeft,
                              child: Container(
                                width: 14,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Thân dưới nhỏ xíu cute có luồng phản lực nhẹ
                          Positioned(
                            bottom: -10,
                            child: Container(
                              width: 28,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF06B6D4)
                                            .withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Bong bóng thoại mời chào cute 3D
                if (_showBubble)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.greetingText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _showBubble = false),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEye(double scaleY) {
    return Transform.scale(
      scaleY: scaleY,
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF22D3EE), // Cyan neon rực sáng
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.9),
              blurRadius: 8,
              spreadRadius: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}
