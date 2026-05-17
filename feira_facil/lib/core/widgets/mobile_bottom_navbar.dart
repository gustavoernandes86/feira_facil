import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_theme.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

enum MobileTab {
  home,
  markets,
  suggested,
  savings,
  settings,
}

class MobileBottomNavbar extends StatelessWidget {
  final MobileTab activeTab;

  const MobileBottomNavbar({
    super.key,
    required this.activeTab,
  });

  void _onTabTapped(BuildContext context, MobileTab tab) {
    if (tab == activeTab) return;
    HapticFeedback.lightImpact();

    switch (tab) {
      case MobileTab.home:
        context.go(RoutePaths.lists);
        break;
      case MobileTab.markets:
        context.go(RoutePaths.markets);
        break;
      case MobileTab.suggested:
        context.go(RoutePaths.suggestedPurchases);
        break;
      case MobileTab.savings:
        context.go(RoutePaths.savings);
        break;
      case MobileTab.settings:
        context.go(RoutePaths.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    // Custom premium colors
    final backgroundColor = isDark 
        ? const Color(0xFF1E1E2F).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.90);
    
    final borderColor = isDark
        ? const Color(0xFF2D2D44).withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.8);
        
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  tab: MobileTab.home,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Início',
                ),
                _buildNavItem(
                  context,
                  tab: MobileTab.markets,
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Mercados',
                ),
                _buildCenterActionItem(context),
                _buildNavItem(
                  context,
                  tab: MobileTab.savings,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Economia',
                ),
                _buildNavItem(
                  context,
                  tab: MobileTab.settings,
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune_rounded,
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required MobileTab tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = tab == activeTab;
    final activeColor = context.colorGreen;
    final inactiveColor = context.colorTextTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(context, tab),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive 
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionItem(BuildContext context) {
    final isActive = activeTab == MobileTab.suggested;
    final activeColor = context.colorOrange;
    
    return InkWell(
      onTap: () => _onTabTapped(context, MobileTab.suggested),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [context.colorOrange, const Color(0xFFFF9E80)]
                      : [context.colorOrange.withValues(alpha: 0.8), context.colorOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.colorOrange.withValues(alpha: isActive ? 0.5 : 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Comparar',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? activeColor : context.colorTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
