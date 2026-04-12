import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import 'group_controller.dart';

class GroupSetupScreen extends ConsumerWidget {
  const GroupSetupScreen({super.key});

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
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
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(groupControllerProvider.notifier).createFamilyGroup(nameController.text.trim());
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
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                ref.read(groupControllerProvider.notifier).joinFamilyGroup(codeController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(groupControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      } else if (!next.isLoading && next.value != null) {
        // Success: group created/joined
        context.go('/feiras');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operação realizada com sucesso!')),
        );
      }
    });

    final groupState = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vamos começar!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.family_restroom,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Você prefere criar um novo grupo para sua família ou entrar em um que já existe?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),
            if (groupState.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Criar um Novo Grupo'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showJoinGroupDialog(context, ref),
                icon: const Icon(Icons.group_add),
                label: const Text('Entrar com Código Convite'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
