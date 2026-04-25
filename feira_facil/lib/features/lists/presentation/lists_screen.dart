import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsync = groupId != null ? ref.watch(fairListsStreamProvider(groupId)) : const AsyncValue.loading();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Text('Listas Base', style: GoogleFonts.fraunces(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return _buildListCard(context, list, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListDialog(context, ref),
        label: const Text('Nova Lista Base', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text(
              'Nenhuma Lista Base',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie uma lista base (ex: "Lista do Mês", "Churrasco") para usar nos mercados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final groupId = ref.read(currentGroupIdProvider);
                final userId = ref.read(currentUserProfileProvider).value?.id;
                if (groupId != null && userId != null) {
                  await ref.read(fairListsControllerProvider(groupId).notifier).checkDefaultList(userId);
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Gerar Lista Essencial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, FairList list, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(list.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, list),
      onDismissed: (_) {
        final groupId = ref.read(currentGroupIdProvider);
        if (groupId != null) {
          ref.read(fairListsControllerProvider(groupId).notifier).deleteList(list.id);
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [AppColors.shadow2],
          border: Border.all(color: AppColors.cream2),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          onTap: () => context.push('/lists/${list.id}', extra: list),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.list_alt, color: AppColors.green),
          ),
          title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Toque para gerenciar itens', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, FairList list) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lista'),
        content: Text('Deseja excluir a lista "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showCreateListDialog(BuildContext context, WidgetRef ref) async {
    String listName = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Lista Base'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da Lista (ex: Compra do Mês)'),
          onChanged: (val) => listName = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final groupId = ref.read(currentGroupIdProvider);
              final userId = ref.read(currentUserProfileProvider).value?.id;
              if (groupId == null || userId == null || listName.trim().isEmpty) return;
              
              await ref.read(fairListsControllerProvider(groupId).notifier).createList(
                name: listName.trim(),
                color: AppColors.green,
                userId: userId,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
