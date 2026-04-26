import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/widgets/premium_header.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_repository.dart';
import '../domain/family_group.dart';
import 'group_controller.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(currentGroupStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    ref.listen(groupControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${next.error}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: groupAsync.when(
        data: (group) {
          final user = userProfileAsync.value;
          final isAdmin = user != null && group != null && group.createdBy == user.id;

          return Column(
            children: [
              PremiumHeader(
                title: group?.name ?? 'Meus Grupos',
                subtitle: isAdmin ? '👑 Você é o administrador' : 'Gerencie membros e grupos da sua família.',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    // Invite code card only if in a group
                    if (group != null) ...[
                      _buildInviteCard(context, group.inviteCode),
                      const SizedBox(height: 32),
                      _buildSectionHeader('MEMBROS DO GRUPO'),
                      const SizedBox(height: 12),
                      _buildMembersList(ref, group, user, isAdmin),
                      const SizedBox(height: 32),
                    ],

                    // All groups the user belongs to
                    if (user != null) ...[
                      _buildSectionHeader('MEUS GRUPOS'),
                      const SizedBox(height: 12),
                      _buildUserGroupsList(context, ref, user, group),
                      const SizedBox(height: 32),
                    ],

                    // Actions section
                    _buildSectionHeader('AÇÕES DE GRUPO'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.add_home_work_rounded,
                      title: 'Criar Novo Grupo',
                      desc: 'Crie um novo grupo e convide sua família.',
                      color: AppColors.orange,
                      onTap: () => _showCreateGroupDialog(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.group_add_rounded,
                      title: 'Entrar em um Grupo',
                      desc: 'Tem um código de convite? Entre agora.',
                      color: AppColors.green,
                      onTap: () => _showJoinGroupDialog(context, ref),
                    ),

                    // Admin-only: delete group
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.delete_forever_rounded,
                        title: 'Excluir Grupo "${group.name}"',
                        desc: 'Remove todos os membros e apaga o grupo permanentemente.',
                        color: AppColors.red,
                        onTap: () => _confirmDeleteGroup(context, ref, group),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cream2),
          boxShadow: const [AppColors.shadow1],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBody)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow1],
        border: Border.all(color: AppColors.cream2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de Convite',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Compartilhe este código com quem você quer no grupo.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(WidgetRef ref, FamilyGroup group, AppUser? currentUser, bool isAdmin) {
    return FutureBuilder<List<AppUser>>(
      future: ref.read(userRepositoryProvider).getUsers(group.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        final users = snapshot.data ?? [];
        return Column(
          children: users.map((user) {
            final isSelf = currentUser?.id == user.id;
            final isCreator = user.id == group.createdBy;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cream2),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.cream,
                  child: Text(
                    user.name?[0].toUpperCase() ?? '?',
                    style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Text(user.name ?? 'Membro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (isCreator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('👑 Admin', style: TextStyle(color: AppColors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelf)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Você', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    // Admin can remove any member except themselves
                    if (isAdmin && !isSelf)
                      IconButton(
                        icon: const Icon(Icons.person_remove_rounded, size: 20),
                        color: AppColors.red,
                        tooltip: 'Remover membro',
                        onPressed: () => _confirmRemoveMember(context, ref, group, user),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Lists all groups the user belongs to so they can switch between them.
  Widget _buildUserGroupsList(BuildContext context, WidgetRef ref, AppUser user, FamilyGroup? activeGroup) {
    return FutureBuilder<List<FamilyGroup>>(
      future: Future.wait(
        user.groupIds.map((id) => ref.read(groupRepositoryProvider).getGroup(id)),
      ).then((groups) => groups.whereType<FamilyGroup>().toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data ?? [];
        return Column(
          children: groups.map((group) {
            final isActive = group.id == activeGroup?.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.greenLT : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? AppColors.green : AppColors.cream2, width: isActive ? 2 : 1),
              ),
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.group_outlined,
                  color: isActive ? AppColors.green : AppColors.textTertiary,
                ),
                title: Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.green : AppColors.textBody)),
                subtitle: Text('${group.memberIds.length} membro(s)', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Ativo', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          await ref.read(groupRepositoryProvider).switchActiveGroup(user.id, group.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Grupo "${group.name}" ativado!')),
                            );
                          }
                        },
                        child: const Text('Ativar'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                      color: AppColors.red,
                      tooltip: 'Sair do grupo',
                      onPressed: () => _confirmLeaveGroup(context, ref, group),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Novo Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do Grupo',
            hintText: 'Ex: Família Silva',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(groupControllerProvider.notifier).createGroup(nameController.text.trim());
                Navigator.pop(ctx);
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
      builder: (ctx) => AlertDialog(
        title: Text('Entrar em um Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de Convite',
            hintText: 'Ex: A1B2C3',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                ref.read(groupControllerProvider.notifier).joinGroupByCode(codeController.text.trim().toUpperCase());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveGroup(BuildContext context, WidgetRef ref, FamilyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sair do Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text(
          'Você tem certeza que quer sair do grupo "${group.name}"?\n\nVocê perderá acesso às listas e ao histórico de preços deste grupo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair do Grupo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await ref.read(groupControllerProvider.notifier).leaveGroup(group.id);
    }
  }

  Future<void> _confirmRemoveMember(BuildContext context, WidgetRef ref, FamilyGroup group, AppUser member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover Membro', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text(
          'Deseja remover ${member.name} do grupo "${group.name}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await ref.read(groupControllerProvider.notifier).removeMember(group.id, member.id);
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context, WidgetRef ref, FamilyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text(
          'Atenção: Você está prestes a excluir o grupo "${group.name}".\n\nIsso removerá todos os membros e apagará o grupo permanentemente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Grupo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await ref.read(groupControllerProvider.notifier).deleteGroup(group.id);
    }
  }
}
