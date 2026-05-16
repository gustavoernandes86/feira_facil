import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

extension ThemeColorsExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isColorblind => Theme.of(this).colorScheme.primary == ColorblindColors.blue;

  // Primary Color (Green)
  Color get colorGreen => Theme.of(this).colorScheme.primary;
  Color get colorGreenDark => isDark ? DraculaColors.greenBackground : (isColorblind ? const Color(0xFF005A8C) : AppColors.greenDark);
  Color get colorGreenLight => isDark ? DraculaColors.green.withValues(alpha: 0.1) : Theme.of(this).colorScheme.primary.withValues(alpha: 0.1);

  // Action Color (Orange)
  Color get colorOrange => Theme.of(this).colorScheme.secondary;
  Color get colorOrangeDark => isDark ? DraculaColors.orange : AppColors.orangeDark;
  Color get colorOrangeLight => isDark ? DraculaColors.orange.withValues(alpha: 0.1) : AppColors.orangeLight;

  Color get colorRed => Theme.of(this).colorScheme.error;
  Color get colorRedLight => Theme.of(this).colorScheme.error.withValues(alpha: 0.1);

  Color get colorBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get colorCard => Theme.of(this).cardTheme.color ?? Theme.of(this).colorScheme.surface;
  Color get colorBorder => isDark ? DraculaColors.comment.withValues(alpha: 0.4) : AppColors.border;

  Color get colorTextPrimary => Theme.of(this).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
  Color get colorTextSecondary => Theme.of(this).textTheme.bodyMedium?.color ?? AppColors.textSecondary;
  Color get colorTextTertiary => Theme.of(this).textTheme.labelLarge?.color ?? AppColors.textTertiary;

  List<BoxShadow>? get shadow1 => isDark ? null : const [AppColors.shadow1];
  List<BoxShadow>? get shadow2 => isDark ? null : const [AppColors.shadow2];
}
