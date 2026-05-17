import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:feira_facil/core/widgets/responsive_wrapper.dart';
import 'package:feira_facil/core/widgets/shared_widgets.dart';
import 'package:feira_facil/core/widgets/web_sidebar.dart';
import 'package:feira_facil/core/widgets/mobile_bottom_navbar.dart';
import 'package:feira_facil/core/widgets/premium_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveWrapper(
      mobile: _buildMobileLayout(context, ref),
      web: _buildWebLayout(context, ref),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? DraculaColors.background : context.colorBackground;
    final cardColor = isDark ? DraculaColors.currentLine : context.colorCard;
    final borderColor = isDark ? DraculaColors.comment.withValues(alpha: 0.2) : context.colorBorder;
    final textColor = isDark ? DraculaColors.foreground : context.colorTextPrimary;
    final subtleColor = isDark ? DraculaColors.comment : context.colorTextSecondary;
    final accentColor = isDark ? DraculaColors.orange : context.colorOrange;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      bottomNavigationBar: const MobileBottomNavbar(activeTab: MobileTab.settings),
      body: Column(
        children: [
          // Header
          const PremiumHeader(
            title: 'Configurações',
            subtitle: 'Preferências e termos',
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                // ── Seção: Aparência ────────────────────────────────────
                _buildSectionHeader('APARÊNCIA', subtleColor),
                const SizedBox(height: 12),
                _buildThemeCard(context, ref, themeMode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                const SizedBox(height: 32),

                // ── Seção: Grupo ────────────────────────────────────────
                _buildSectionHeader('GRUPO FAMILIAR', subtleColor),
                const SizedBox(height: 12),

                _buildActionCard(
                  icon: Icons.group_rounded,
                  title: 'Gerenciar Grupos',
                  desc: 'Crie, entre ou gerencie seus grupos.',
                  color: isDark ? DraculaColors.green : context.colorGreen,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  onTap: () => context.push('/group-management'),
                ),

                const SizedBox(height: 32),

                // ── Seção: Conta e Privacidade ───────────────────────────
                _buildSectionHeader('CONTA E PRIVACIDADE', subtleColor),
                const SizedBox(height: 12),

                _buildActionCard(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  desc: 'Leia nossas regras de utilização.',
                  color: accentColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  onTap: () => context.push(RoutePaths.termsOfUse),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidade',
                  desc: 'Como cuidamos dos seus dados.',
                  color: isDark ? DraculaColors.cyan : context.colorGreen,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  onTap: () => context.push(RoutePaths.privacyPolicy),
                ),
                const SizedBox(height: 24),
                
                // Delete Account Button
                _buildDeleteAccountButton(context, ref, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Web Layout ──────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? DraculaColors.background : context.colorBackground;
    final cardColor = isDark ? DraculaColors.currentLine : context.colorCard;
    final borderColor = isDark ? DraculaColors.comment.withValues(alpha: 0.2) : context.colorBorder;
    final textColor = isDark ? DraculaColors.foreground : context.colorTextPrimary;
    final subtleColor = isDark ? DraculaColors.comment : context.colorTextSecondary;
    final accentColor = isDark ? DraculaColors.orange : context.colorOrange;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar is included but settings is not direct, so no active nav highlighting
          const WebSidebar(active: NavSection.settings),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(
                  title: 'Configurações',
                  subtitle: 'Gerencie preferências de interface, grupo familiar e termos de uso do sistema.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column 1: Appearance and Theme
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('APARÊNCIA', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildThemeCard(context, ref, themeMode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Column 2: Family group management & legal docs & dangerous settings
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('GRUPO FAMILIAR', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.group_rounded,
                                    title: 'Gerenciar Grupos',
                                    desc: 'Crie, entre ou gerencie seus grupos.',
                                    color: isDark ? DraculaColors.green : context.colorGreen,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtleColor: subtleColor,
                                    onTap: () => context.push('/group-management'),
                                  ),
                                  const SizedBox(height: 28),

                                  _buildSectionHeader('CONTA E PRIVACIDADE', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.description_outlined,
                                    title: 'Termos de Uso',
                                    desc: 'Leia nossas regras de utilização.',
                                    color: accentColor,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtleColor: subtleColor,
                                    onTap: () => context.push(RoutePaths.termsOfUse),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.privacy_tip_outlined,
                                    title: 'Política de Privacidade',
                                    desc: 'Como cuidamos dos seus dados.',
                                    color: isDark ? DraculaColors.cyan : context.colorGreen,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtleColor: subtleColor,
                                    onTap: () => context.push(RoutePaths.privacyPolicy),
                                  ),
                                  const SizedBox(height: 28),

                                  _buildDeleteAccountButton(context, ref, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, WidgetRef ref, bool isDark) {
    return InkWell(
      onTap: () => _showDeleteConfirmation(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: context.colorRed.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: context.colorRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'Excluir Minha Conta',
              style: TextStyle(
                color: context.colorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é permanente. Todos os seus dados pessoais serão removidos dos nossos servidores de acordo com a LGPD.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: context.colorTextTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, excluir tudo'),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }

  // ─── Theme Card ──────────────────────────────────────────────────────────────

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode themeMode,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtleColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : context.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette_outlined, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema Visual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    Text('Escolha entre claro e escuro (Dracula)', style: TextStyle(fontSize: 12, color: subtleColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _themeOption(
                label: 'Sistema / Claro',
                icon: Icons.brightness_auto_rounded,
                selected: themeMode == AppThemeMode.system,
                color: context.colorOrange,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(AppThemeMode.system),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'Escuro',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == AppThemeMode.dark,
                color: isDark ? DraculaColors.purple : context.colorGreen,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(AppThemeMode.dark),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'Daltônico',
                icon: Icons.visibility_rounded,
                selected: themeMode == AppThemeMode.colorblind,
                color: const Color(0xFF0072B2), // ColorblindColors.blue
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(AppThemeMode.colorblind),
              ),
            ],
          ),
          if (themeMode == AppThemeMode.dark) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DraculaColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DraculaColors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🧛', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tema Dracula ativo — baseado no tema do VS Code',
                      style: TextStyle(fontSize: 12, color: isDark ? DraculaColors.purple : context.colorTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required Color textColor,
    required Color subtleColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : subtleColor.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : subtleColor, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : subtleColor,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Action Card ─────────────────────────────────────────────────────────────

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: subtleColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
