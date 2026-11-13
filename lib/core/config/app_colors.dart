import 'package:flutter/material.dart';

class AppColors {
  // Brand 3D Palette - Deep Space & Electric Glow
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const darkBlue = Color(0xFF0F172A);
  static const primarySoft = Color(0xFFEFF6FF);

  // Background không gian 3D
  static const background = Color(0xFFF1F5F9); // Slate 100 cao cấp
  static const backgroundDark = Color(0xFF0B0F19);
  static const card = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E293B);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

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
