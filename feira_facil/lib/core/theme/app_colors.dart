import 'package:flutter/material.dart';

class AppColors {
  // Orange Palette
  static const Color orange = Color(0xFFF4620A);
  static const Color orangeDark = Color(0xFFC94E06);
  static const Color orangeLight = Color(0xFFFF8C42);
  static const Color orangeLT = Color(0xFFFF8C42); // Light orange alias
  static const Color orangeUltraLight = Color(0xFFFFF0E8);
  static const Color orangeMedium = Color(0xFFFFBA94);

  // Green Palette
  static const Color green = Color(0xFF2E7D32);
  static const Color greenDark = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color greenLT = Color(0xFFE8F5E9); // Light green alias
  static const Color greenMedium = Color(0xFFA5D6A7);

  // Red Palette
  static const Color red = Color(0xFFD32F2F);
  static const Color redLight = Color(0xFFFFEBEE);

  // Cream Palette
  static const Color cream = Color(0xFFFFF8F2);
  static const Color cream2 = Color(0xFFFFE8D6);

  // Text Palette
  static const Color textBody = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF4A6B4A);
  static const Color textTertiary = Color(0xFF8FAF8F);

  // Basics
  static const Color white = Color(0xFFFFFFFF);

  // Shadows & Misc
  static const BoxShadow shadow1 = BoxShadow(
    color: Color(0x21F4620A), // rgba(244, 98, 10, 0.13)
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadow2 = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    blurRadius: 10,
    offset: Offset(0, 2),
  );

  // Border Radius
  static const double radiusLarge = 18.0;
  static const double radiusMedium = 12.0;
  static const double radiusSmall = 8.0;
}
