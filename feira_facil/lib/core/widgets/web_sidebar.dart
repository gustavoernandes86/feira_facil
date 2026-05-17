import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';
import '../providers/user_providers.dart';
import '../router/app_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/presentation/notifications_controller.dart';
import 'shared_widgets.dart';

enum NavSection { home, markets, suggested, savings, notifications, settings }

class WebSidebar extends ConsumerWidget {
  final NavSection active;

  const WebSidebar({
    super.key,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final activeGroup = ref.watch(currentGroupStreamProvider).value;
    final unreadCount = ref.watch(unreadNotificationsProvider).value?.length ?? 0;

    final userName = userProfile?.name ?? 'Usuário';
    final userEmail = userProfile?.email ?? '';
    final groupName = activeGroup?.name ?? 'Minha Família';

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.colorCard,
        border: Border(
          right: BorderSide(color: context.colorBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colorGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Feira Fácil',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colorGreen,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grupo (Clica para ir ao gerenciamento de grupo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => context.pushNamed(RouteNames.groupManagement),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.colorBackground,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  border: Border.all(color: context.colorBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        color: context.colorGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        groupName,
                        style: GoogleFonts.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colorTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.swap_horiz_rounded,
                        size: 16, color: context.colorTextTertiary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Nav Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                WebSidebarNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Início',
                  isActive: active == NavSection.home,
                  onTap: () => context.goNamed(RouteNames.lists),
                ),
                WebSidebarNavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Mercados',
                  isActive: active == NavSection.markets,
                  onTap: () => context.goNamed(RouteNames.markets),
                ),
                WebSidebarNavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome_rounded,
                  label: 'Compras Sugeridas',
                  isActive: active == NavSection.suggested,
                  onTap: () => context.goNamed(RouteNames.suggestedPurchases),
                ),
                WebSidebarNavItem(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up_rounded,
                  label: 'Minha Economia',
                  isActive: active == NavSection.savings,
                  onTap: () => context.goNamed(RouteNames.savings),
                ),
                WebSidebarNavItem(
                  icon: Icons.notifications_none_rounded,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Notificações',
                  isActive: active == NavSection.notifications,
                  onTap: () => context.goNamed(RouteNames.notifications),
                  badgeCount: unreadCount,
                ),
                const Divider(height: 24),
                WebSidebarNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Configurações',
                  isActive: active == NavSection.settings,
                  onTap: () => context.goNamed(RouteNames.settings),
                ),
              ],
            ),
          ),

          // Rodapé User
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colorGreenLight,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: context.colorGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colorTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colorTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout_rounded,
                      size: 18, color: context.colorRed),
                  tooltip: 'Sair',
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WebTopBar ────────────────────────────────────────────────────────────────
class WebTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const WebTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: context.colorCard,
        border: Border(
          bottom: BorderSide(color: context.colorBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) Row(children: actions!),
        ],
      ),
    );
  }
}

// ─── WebActionButton ─────────────────────────────────────────────────────────
class WebActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool secondary;

  const WebActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorTextSecondary,
          side: BorderSide(color: context.colorBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colorGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );
  }
}
