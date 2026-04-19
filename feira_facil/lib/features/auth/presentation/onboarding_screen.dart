import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Dots
              Row(
                children: List.generate(3, (index) {
                  final isCurrent = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.orange : AppColors.cream2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildStep(
                      emoji: '🛒',
                      title: 'Bem-vindo ao\n',
                      titleEmphasis: 'Feira Fácil!',
                      sub: 'Compare preços, economize na feira e faça as compras em família — tudo em um só lugar.',
                      chips: [
                        '📷 OCR de etiquetas',
                        '👨‍👩‍👧 Família em tempo real',
                        '🏪 Comparar mercados',
                        '💰 Controle de orçamento',
                      ],
                      logoWidget: Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    _buildStep(
                      emoji: '📊',
                      title: 'Economia\n',
                      titleEmphasis: 'Inteligente',
                      sub: 'Cadastre preços tirando fotos das etiquetas e deixe que a gente calcula a melhor oferta para você.',
                      chips: [
                        'Historico de preços',
                        'Gráficos interativos',
                        'Alertas de economia',
                      ],
                    ),
                    _buildStep(
                      emoji: '👨‍👩‍👧',
                      title: 'Compras em\n',
                      titleEmphasis: 'Família',
                      sub: 'Sincronize sua lista com todos da casa. Veja quem pegou o quê em tempo real no mercado.',
                      chips: [
                        'Listas compartilhadas',
                        'Notificações push',
                        'Gestão multi-usuário',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: const Text('Criar minha conta'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: const Text('Já tenho conta — Entrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String emoji,
    required String title,
    required String titleEmphasis,
    required String sub,
    required List<String> chips,
    Widget? logoWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget ?? Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 30),
            children: [
              TextSpan(text: title),
              TextSpan(
                text: titleEmphasis,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: chips.map((c) => _buildPill(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
