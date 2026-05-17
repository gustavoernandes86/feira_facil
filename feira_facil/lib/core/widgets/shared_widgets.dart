import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

// ─── DotPainter ──────────────────────────────────────────────────────────────
class DotPainter extends CustomPainter {
  final double spacing;
  const DotPainter({this.spacing = 22.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── StatusBadge ─────────────────────────────────────────────────────────────
enum ListStatus { active, shopping, done, suggested }

class StatusBadge extends StatelessWidget {
  final ListStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ListStatus.active =>
        ('Ativa', context.colorGreenLight, context.colorGreen),
      ListStatus.shopping =>
        ('No Mercado', context.colorOrangeLight, context.colorOrange),
      ListStatus.done => (
          'Concluída',
          context.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          context.colorTextTertiary,
        ),
      ListStatus.suggested =>
        ('Feira', context.colorOrangeLight, context.colorOrange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─── ProgressRow ─────────────────────────────────────────────────────────────
class ProgressRow extends StatelessWidget {
  final int checked;
  final int total;
  final Color? color;

  const ProgressRow({
    super.key,
    required this.checked,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? checked / total : 0.0;
    final pct = (progress * 100).toInt();
    final barColor = color ?? context.colorGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$checked de $total itens pegos',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colorTextSecondary,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─── SectionHeader ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? titleColor;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.titleColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: titleColor ?? context.colorOrange, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor ?? context.colorOrange,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12,
                color: context.colorGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── HeaderIconButton ─────────────────────────────────────────────────────────
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  const HeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: context.colorRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorGreen,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── StatChip ────────────────────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String value;
  final String label;

  const StatChip({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WebMetricCard ────────────────────────────────────────────────────────────
class WebMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final IconData icon;
  final VoidCallback? onTap;

  const WebMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: context.colorBorder),
          boxShadow: context.shadow2,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colorGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
              child: Icon(icon, color: context.colorGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.colorTextTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.colorTextPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor ?? context.colorGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: context.colorTextTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── WebSidebarNavItem ────────────────────────────────────────────────────────
class WebSidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const WebSidebarNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colorOrange;
    final inactiveColor = context.colorTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.normal,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colorRed,
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
