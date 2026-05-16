import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo colorida no body
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Compare preços.\nEconomize toda semana.',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: context.colorTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'O app que transforma sua feira\nem economia inteligente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.colorTextSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Google Sign-In Button (SaaS Style)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusLg),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.g_mobiledata_rounded, size: 32),
                      label: Text(
                        isLoading ? 'Conectando...' : 'Entrar com Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Fazemos login apenas com sua conta Google\npara maior segurança e privacidade',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorTextTertiary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Features preview
                  _buildFeatureItem(
                    context: context,
                    icon: '🛒',
                    title: 'Listas Inteligentes',
                    description: 'Organize suas compras por categoria',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    context: context,
                    icon: '💰',
                    title: 'Compare Preços',
                    description: 'Encontre as melhores ofertas',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    context: context,
                    icon: '👨‍👩‍👧‍👦',
                    title: 'Compartilhe',
                    description: 'Sincronize com sua família',
                  ),

                  const SizedBox(height: 50),

                  // Legal Links
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
        ],
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: context.isDark ? context.colorGreenDark : context.colorGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: DotPainter(spacing: 22)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo-horizontal-escura.png',
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colorTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DotPainter extends CustomPainter {
  final double spacing;
  DotPainter({this.spacing = 24.0});

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
