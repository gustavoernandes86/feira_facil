import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final errorString = next.error.toString().toLowerCase();
        // Ignore user cancellation errors
        if (errorString.contains('canceled') || 
            errorString.contains('cancelled') || 
            errorString.contains('sign_in_canceled')) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: ${next.error}'),
            backgroundColor: context.colorRed,
          ),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // 1. Styled Shopping Cart Rounded Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colorGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: context.shadow1,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Main Title (Serif Fraunces)
                Text(
                  'Compare preços.\nEconomize toda semana.',
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.colorTextPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 3. Subtitle (DM Sans)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'O app que transforma sua feira em economia inteligente para toda a família.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colorTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Sign-In Button (SaaS Pill Style)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: context.colorGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Entrar com Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Sub-button copy: "Acesso rápido · seguro · gratuito"
                Text(
                  'Acesso rápido · seguro · gratuito',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorTextTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),

                // 6. Subtle Divider
                Divider(
                  color: context.colorBorder,
                  thickness: 1,
                ),
                const SizedBox(height: 24),

                // 7. Feature Header
                Text(
                  'Por que usar o Feira Fácil?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? context.colorGreen : context.colorGreenDark,
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Feature Card 1
                _buildFeatureCard(
                  context,
                  icon: Icons.bar_chart_rounded,
                  iconBg: context.colorGreenLight,
                  iconColor: context.colorGreen,
                  title: 'Compara mercados automaticamente',
                  subtitle: 'Encontra onde cada item é mais barato',
                ),
                const SizedBox(height: 12),

                // 9. Feature Card 2
                _buildFeatureCard(
                  context,
                  icon: Icons.people_outline_rounded,
                  iconBg: context.colorOrangeLight,
                  iconColor: context.colorOrange,
                  title: 'Lista compartilhada em tempo real',
                  subtitle: 'Toda família sincronizada no mercado',
                ),
                const SizedBox(height: 48),

                // 10. Legal Consent Links
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    _buildLegalLink(
                      context,
                      'Termos de Uso',
                      () => context.push(RoutePaths.termsOfUse),
                    ),
                    Text(
                      '•',
                      style: TextStyle(color: context.colorTextTertiary),
                    ),
                    _buildLegalLink(
                      context,
                      'Política de Privacidade',
                      () => context.push(RoutePaths.privacyPolicy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ao entrar, você concorda com nossos termos.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colorTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalLink(BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: context.colorGreen,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: context.colorBorder),
        boxShadow: context.shadow1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
