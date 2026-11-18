import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppColors {
  // Brand Palette - Unified COFER Navy & Royal Blue
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryDeep = Color(0xFF1E3A8A);
  static const darkBlue = Color(0xFF0F172A);
  static const primarySoft = Color(0xFFEFF6FF);
  static const accentBlue = Color(0xFF0284C7);
  static const slateBlue = Color(0xFF3B82F6);

  static bool get isDark => ThemeService.instance.isDarkMode;

  // Static constants (dùng cho const constructors trên toàn app)
  static const background = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFF0B1120);
  static const card = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E293B);
  static const textPrimary = Color(0xFF0F172A);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF64748B);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF334155);
  static const cardSubtleLight = Color(0xFFF1F5F9);
  static const cardSubtleDark = Color(0xFF0F172A);

  // Background & Surface thích ứng linh hoạt theo Dark/Light Mode
  static Color get adaptiveBackground => isDark ? backgroundDark : background;
  static Color get adaptiveCard => isDark ? cardDark : card;
  static Color get adaptiveCardSubtle => isDark ? cardSubtleDark : cardSubtleLight;
  static Color get adaptiveBorder => isDark ? borderDark : border;
  static Color get adaptiveTextPrimary => isDark ? textPrimaryDark : textPrimary;
  static Color get adaptiveTextSecondary => isDark ? textSecondaryDark : textSecondary;
  static Color get adaptiveAppBarBg => isDark ? backgroundDark : Colors.white;
  static Color get adaptiveInputFill => isDark ? cardDark : background;

  // Tiện ích alias cho các màn hình
  static Color get cardSubtle => adaptiveCardSubtle;
  static Color get appBarBg => adaptiveAppBarBg;

  // Constants phục vụ Theme definitions
  static const backgroundLight = Color(0xFFF8FAFC);
  static const cardLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);
  static const borderLight = Color(0xFFE2E8F0);

  // Semantic & Unified Brand Accent Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const purple = Color(0xFF1D4ED8);
  static const cyan = Color(0xFF0284C7);
  static const teal = Color(0xFF0369A1);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFF3B82F6);

  // Unified Brand Gradients
  static const card3DGradient = LinearGradient(
    begin: Alignment(-0.9, -0.9),
    end: Alignment(0.9, 0.9),
    colors: [
      Color(0xFF0F172A),
      Color(0xFF172554),
      Color(0xFF1E3A8A),
      Color(0xFF2563EB),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const chipGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDBEAFE),
      Color(0xFF93C5FD),
      Color(0xFF3B82F6),
      Color(0xFFEFF6FF),
    ],
  );

  static const neonButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
  );

  static const emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
  );
}
