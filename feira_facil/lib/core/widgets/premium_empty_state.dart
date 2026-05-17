import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_theme.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String iconEmoji;
  final IconData? iconData;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.iconEmoji = '🔍',
    this.iconData,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colorBorder.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: context.shadow1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (iconData != null ? context.colorGreen : context.colorOrange)
                  .withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: (iconData != null ? context.colorGreen : context.colorOrange)
                    .withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: iconData != null
                ? Icon(
                    iconData,
                    size: 40,
                    color: context.colorGreen,
                  )
                : Text(
                    iconEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colorTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: context.colorTextSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButtonPressed != null) ...[
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: context.colorGreen.withValues(alpha: 0.4),
              ),
              child: Text(
                buttonLabel!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
