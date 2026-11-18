import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';

/// Hiệu ứng khung xương tải trang (Skeleton Shimmer) thích ứng Dark/Light Mode
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

/// Khối hình chữ nhật giả lập dữ liệu Shimmer
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Thẻ Card khung xương mô phỏng danh sách hoạt động hoặc mục dữ liệu
class ShimmerCardSkeleton extends StatelessWidget {
  const ShimmerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 80, height: 22, borderRadius: 8),
                ShimmerBox(width: 50, height: 22, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 16, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerBox(width: 220, height: 16, borderRadius: 6),
            const SizedBox(height: 14),
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                const SizedBox(width: 8),
                ShimmerBox(width: 140, height: 12, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                const SizedBox(width: 8),
                ShimmerBox(width: 180, height: 12, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Danh sách khung xương cho ListView loading
class ShimmerListLoading extends StatelessWidget {
  const ShimmerListLoading({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ShimmerCardSkeleton(),
    );
  }
}
