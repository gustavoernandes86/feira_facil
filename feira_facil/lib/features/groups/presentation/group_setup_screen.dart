import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_header.dart';
import '../../auth/presentation/auth_controller.dart';
import 'group_controller.dart';

class GroupSetupScreen extends ConsumerWidget {
  const GroupSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(groupControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (!next.isLoading) {
        // GroupController completed (void type), navigate away
        context.go('/lists');
      }
    });

    final groupState = ref.watch(groupControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          PremiumHeader(
            title: 'Vamos começar!',
            subtitle: 'Configure seu grupo familiar para comparar preços',
            leading: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(' 👋 ', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 20),
                  Text(
                    'Para usar o Feira Fácil, você precisa fazer parte de um grupo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildOptionCard(
                    context: context,
                    icon: Icons.add_home_work_rounded,
                    title: 'Criar Novo Grupo',
                    desc:
                        'Crie um espaço para sua família e convide outros membros.',
                    onTap: () => _showCreateGroupDialog(context, ref),
                    color: AppColors.orange,
                  ),

                  const SizedBox(height: 16),

                  _buildOptionCard(
                    context: context,
                    icon: Icons.group_add_rounded,
                    title: 'Entrar em um Grupo',
                    desc:
                        'Já tem um convite? Cole o código para entrar no grupo.',
                    onTap: () => _showJoinGroupDialog(context, ref),
                    color: AppColors.green,
                  ),

                  if (groupState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: const [AppColors.shadow2],
          border: Border.all(color: AppColors.cream2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Grupo Familiar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Grupo',
            hintText: 'Ex: Família Silva',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref
                    .read(groupControllerProvider.notifier)
                    .createGroup(nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinGroupDialog(BuildContext context, WidgetRef ref) async {
    final codeController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrar em um Grupo'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Código de Convite',
            hintText: 'Ex: A1B2C3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                ref
                    .read(groupControllerProvider.notifier)
                    .joinGroupByCode(codeController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}
