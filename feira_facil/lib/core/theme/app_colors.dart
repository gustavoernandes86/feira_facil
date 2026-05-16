import 'package:flutter/material.dart';

class AppColors {
  // ─── Color Tokens ─────────────────────────────────────────────────────────
  
  // Primary (Green) - Brand identity
  static const Color green = Color(0xFF1A6B3C);
  static const Color greenDark = Color(0xFF0F4A28);
  static const Color greenLight = Color(0xFFE8F5EE);
  static const Color greenMedium = Color(0xFF7ABF9A);

  // Action (Orange) - Buttons, FAB, Values
  static const Color orange = Color(0xFFE85D04);
  static const Color orangeDark = Color(0xFFBF4800);
  static const Color orangeLight = Color(0xFFFFF0E6);
  static const Color orangeMedium = Color(0xFFF4A070);

  // Status
  static const Color red = Color(0xFFC62828);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);

  // Background & Surfaces
  static const Color background = Color(0xFFFAFAF7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEEE9E2);
  static const Color white = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0F1F0F);
  static const Color textSecondary = Color(0xFF3A6A3A);
  static const Color textTertiary = Color(0xFF7A9B7A);

  // ─── Layout Tokens ────────────────────────────────────────────────────────
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 99.0;

  // ─── Shadows ──────────────────────────────────────────────────────────────
  
  static const BoxShadow shadow1 = BoxShadow(
    color: Color(0x21F4620A), // laranja 13% alpha
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadow2 = BoxShadow(
    color: Color(0x14000000), // preto 8% alpha
    blurRadius: 10,
    offset: Offset(0, 2),
  );
}
