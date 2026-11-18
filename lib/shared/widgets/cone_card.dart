import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';

class COneCard extends StatelessWidget {
  const COneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.gradient,
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.adaptiveCard : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: gradient == null
            ? Border.all(color: AppColors.adaptiveBorder, width: 0.8)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: content,
              ),
      ),
    );
  }
}
