import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ─── Dracula Palette ─────────────────────────────────────────────────────────
class DraculaColors {
  static const background  = Color(0xFF282A36);
  static const currentLine = Color(0xFF44475A);
  static const foreground  = Color(0xFFF8F8F2);
  static const comment     = Color(0xFF6272A4);
  static const green       = Color(0xFF50FA7B);
  static const orange      = Color(0xFFFFB86C);
  static const purple      = Color(0xFFBD93F9);
  static const red         = Color(0xFFFF5555);
  static const cyan        = Color(0xFF8BE9FD);
  static const surface0    = Color(0xFF21222C);
  static const surface1    = Color(0xFF343746);
}

// ─── Colorblind Palette (Okabe-Ito) ──────────────────────────────────────────
class ColorblindColors {
  static const blue    = Color(0xFF0072B2); // Positive / Success
  static const orange  = Color(0xFFD55E00); // Negative / Error / Warning
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.green,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        error: AppColors.red,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,

      // Typography
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textBody,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        titleLarge: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textBody),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.9,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textBody),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: const BorderSide(color: AppColors.cream2, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: const BorderSide(color: AppColors.cream2, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textTertiary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orangeMedium, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get colorblindTheme {
    final base = lightTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        secondary: ColorblindColors.blue,
        error: ColorblindColors.orange,
      ),
    );
  }

  // ─── Dark Theme (Dracula) ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: DraculaColors.orange,
        onPrimary: DraculaColors.background,
        secondary: DraculaColors.green,
        onSecondary: DraculaColors.background,
        error: DraculaColors.red,
        onError: DraculaColors.foreground,
        surface: DraculaColors.currentLine,
        onSurface: DraculaColors.foreground,
        outline: DraculaColors.comment,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: DraculaColors.background,

      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.fraunces(fontSize: 32, fontWeight: FontWeight.w800, color: DraculaColors.foreground),
        displayMedium: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: DraculaColors.foreground),
        titleLarge: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: DraculaColors.foreground),
        titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: DraculaColors.foreground),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: DraculaColors.foreground),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: DraculaColors.comment),
        labelLarge: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: DraculaColors.comment, letterSpacing: 0.9),
      ).apply(bodyColor: DraculaColors.foreground, displayColor: DraculaColors.foreground),

      appBarTheme: AppBarTheme(
        backgroundColor: DraculaColors.surface0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: DraculaColors.foreground),
        titleTextStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: DraculaColors.foreground),
      ),

      cardTheme: CardThemeData(
        color: DraculaColors.currentLine,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusLarge)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DraculaColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: const BorderSide(color: DraculaColors.comment, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: BorderSide(color: DraculaColors.comment.withValues(alpha: 0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: const BorderSide(color: DraculaColors.orange, width: 1.5),
        ),
        labelStyle: const TextStyle(color: DraculaColors.comment),
        hintStyle: TextStyle(color: DraculaColors.comment.withValues(alpha: 0.6)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DraculaColors.orange,
          foregroundColor: DraculaColors.background,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DraculaColors.orange,
          side: BorderSide(color: DraculaColors.orange.withValues(alpha: 0.5), width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: DraculaColors.currentLine,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: DraculaColors.foreground),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: DraculaColors.currentLine,
        contentTextStyle: const TextStyle(color: DraculaColors.foreground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
