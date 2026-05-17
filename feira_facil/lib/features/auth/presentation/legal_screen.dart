import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

import 'package:feira_facil/core/widgets/premium_header.dart';

enum LegalType { privacyPolicy, termsOfUse }

class LegalScreen extends StatelessWidget {
  final LegalType type;

  const LegalScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final title = type == LegalType.privacyPolicy 
        ? 'Política de Privacidade' 
        : 'Termos de Uso';

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: Column(
        children: [
          PremiumHeader(
            title: title,
            subtitle: 'Informações e transparência',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Última atualização: 16 de Maio de 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorTextTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContent(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (type == LegalType.privacyPolicy) {
      return _buildPrivacyPolicy(context);
    } else {
      return _buildTermsOfUse(context);
    }
  }

  Widget _buildPrivacyPolicy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, '1. Introdução'),
        _sectionBody(context, 'O Feira Fácil valoriza a sua privacidade. Esta política explica como coletamos, usamos e protegemos seus dados pessoais de acordo com a LGPD.'),
        
        _sectionTitle(context, '2. Dados Coletados'),
        _sectionBody(context, 'Coletamos apenas o necessário para o funcionamento do app:\n• Nome e E-mail (via login do Google)\n• Foto de perfil (opcional, via Google)\n• Listas de compras e preços cadastrados'),
        
        _sectionTitle(context, '3. Finalidade'),
        _sectionBody(context, 'Seus dados são usados exclusivamente para permitir a sincronização das listas com sua família e para personalizar sua experiência no app.'),
        
        _sectionTitle(context, '4. Seus Direitos'),
        _sectionBody(context, 'De acordo com a LGPD, você tem direito a:\n• Acessar seus dados\n• Corrigir dados incompletos ou errados\n• Solicitar a exclusão total dos seus dados a qualquer momento nas configurações do app.'),
        
        _sectionTitle(context, '5. Segurança'),
        _sectionBody(context, 'Utilizamos infraestrutura segura (Google Firebase) para garantir que seus dados estejam protegidos contra acessos não autorizados.'),
      ],
    );
  }

  Widget _buildTermsOfUse(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, '1. Aceitação dos Termos'),
        _sectionBody(context, 'Ao utilizar o Feira Fácil, você concorda com estes termos. O app é uma ferramenta para auxiliar na organização de compras e comparação de preços.'),
        
        _sectionTitle(context, '2. Uso do Aplicativo'),
        _sectionBody(context, 'Você é responsável pelas informações cadastradas e pelo compartilhamento de suas listas com outros usuários (membros da família).'),
        
        _sectionTitle(context, '3. Limitação de Responsabilidade'),
        _sectionBody(context, 'O Feira Fácil não garante a disponibilidade de produtos ou a precisão absoluta dos preços, que são cadastrados pelos próprios usuários ou capturados de etiquetas via OCR.'),
        
        _sectionTitle(context, '4. Modificações'),
        _sectionBody(context, 'Podemos atualizar estes termos ocasionalmente. O uso contínuo do app após as mudanças constitui aceitação dos novos termos.'),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.colorGreen,
        ),
      ),
    );
  }

  Widget _sectionBody(BuildContext context, String body) {
    return Text(
      body,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: context.colorTextSecondary,
      ),
    );
  }
}
