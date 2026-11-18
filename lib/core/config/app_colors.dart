import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppColors {
  // Brand 3D Palette - Deep Space & Electric Glow
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const darkBlue = Color(0xFF0F172A);
  static const primarySoft = Color(0xFFEFF6FF);

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

  // Neon & Semantic Colors với độ rực 3D
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);
  static const teal = Color(0xFF14B8A6);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFFBBF24);

  // 3D Gradients phản quang
  static const card3DGradient = LinearGradient(
    begin: Alignment(-0.9, -0.9),
    end: Alignment(0.9, 0.9),
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF1E3A8A),
      Color(0xFF2563EB),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const chipGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDF7A),
      Color(0xFFD4AF37),
      Color(0xFF996515),
      Color(0xFFFFE599),
    ],
  );

  static const neonButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFF6D28D9)],
  );

  static const emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );
}
