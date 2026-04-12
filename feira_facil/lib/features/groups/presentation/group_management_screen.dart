import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/user_providers.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_repository.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(currentGroupStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão do Grupo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Nenhum grupo selecionado.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Nome do Grupo Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.groups, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      group.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seu grupo está ativo e pronto!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Invite Code Section
              const Text(
                'CONVIDAR MEMBROS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Código de Convite', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            group.inviteCode,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: group.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado para a área de transferência!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      style: IconButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Members List Section
              const Text(
                'MEMBROS DO GRUPO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<AppUser>>(
                future: ref.read(userRepositoryProvider).getUsers(group.memberIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  final users = snapshot.data ?? [];
                  return Column(
                    children: users.map((user) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(user.name?[0] ?? '?', style: TextStyle(color: Colors.green.shade800)),
                      ),
                      title: Text(user.name ?? 'Membro s/ nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email),
                      trailing: userProfileAsync.value?.id == user.id 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Você', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : null,
                    )).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Switch Group Section (if multiple groups)
              userProfileAsync.when(
                data: (user) {
                  if (user == null || user.groupIds.length <= 1) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TROCAR DE GRUPO',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      const Text('Você participa de outros grupos. Toque abaixo para alternar:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 16),
                      // This would normally be a list of groups fetched by ID
                      // For simplicity, we'll show a button to open a selection dialog or just a placeholder
                      ElevatedButton(
                        onPressed: () => _showSwitchGroupDialog(context, ref, user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Alternar Grupo Ativo'),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _showSwitchGroupDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar Grupo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: user.groupIds.length,
            itemBuilder: (context, index) {
              final groupId = user.groupIds[index];
              return ListTile(
                title: Text('Grupo $groupId'), // We would ideally fetch the group name here
                onTap: () async {
                  await ref.read(groupRepositoryProvider).switchActiveGroup(user.id, groupId);
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to Home which will refresh
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
