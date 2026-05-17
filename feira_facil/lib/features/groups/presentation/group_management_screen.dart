import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_providers.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_repository.dart';
import '../domain/family_group.dart';
import 'group_controller.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:feira_facil/core/widgets/responsive_wrapper.dart';
import 'package:feira_facil/core/widgets/shared_widgets.dart';
import 'package:feira_facil/core/widgets/web_sidebar.dart';
import 'package:feira_facil/core/widgets/premium_header.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(currentGroupStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(groupControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${next.error}'),
            backgroundColor: context.colorRed,
          ),
        );
      }
    });

    final bgColor = isDark ? DraculaColors.background : context.colorBackground;
    final cardColor = isDark ? DraculaColors.currentLine : context.colorCard;
    final borderColor = isDark ? DraculaColors.comment.withValues(alpha: 0.2) : context.colorBorder;
    final textColor = isDark ? DraculaColors.foreground : context.colorTextPrimary;
    final subtleColor = isDark ? DraculaColors.comment : context.colorTextSecondary;
    final accentColor = isDark ? DraculaColors.orange : context.colorOrange;

    return groupAsync.when(
      data: (group) {
        final user = userProfileAsync.value;
        final isAdmin = user != null && group != null && group.createdBy == user.id;

        return ResponsiveWrapper(
          mobile: Scaffold(
            backgroundColor: bgColor,
            body: _buildMobileBody(context, ref, group, user, isAdmin, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
          ),
          web: Scaffold(
            backgroundColor: bgColor,
            body: _buildWebBody(context, ref, group, user, isAdmin, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: context.colorGreen)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('Erro: $err')),
      ),
    );
  }

  // ── Mobile Body Layout ─────────────────────────────────────────────────────
  Widget _buildMobileBody(
    BuildContext context,
    WidgetRef ref,
    FamilyGroup? group,
    AppUser? user,
    bool isAdmin,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtleColor,
    Color accentColor,
  ) {
    return Column(
      children: [
        // Header
        const PremiumHeader(
          title: 'Gerenciar Grupos',
          subtitle: 'Configurações de grupo familiar',
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              if (group != null && user != null) ...[
                _buildSectionHeader('MEUS GRUPOS', subtleColor),
                const SizedBox(height: 12),
                _buildUserGroupsList(context, ref, user, group, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                const SizedBox(height: 24),
              ],

              if (group != null) ...[
                _buildSectionHeader('GRUPO FAMILIAR ATUAL', subtleColor),
                const SizedBox(height: 12),
                _buildInviteCard(context, group.inviteCode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                const SizedBox(height: 16),
                _buildSectionHeader('MEMBROS', subtleColor),
                const SizedBox(height: 12),
                _buildMembersList(ref, group, user, isAdmin, isDark, cardColor, borderColor, textColor, subtleColor),
                const SizedBox(height: 24),
              ],

              _buildSectionHeader('AÇÕES', subtleColor),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.add_home_work_rounded,
                title: 'Criar Novo Grupo',
                desc: 'Crie um novo grupo e convide sua família.',
                color: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => _showCreateGroupDialog(context, ref),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.group_add_rounded,
                title: 'Entrar em um Grupo',
                desc: 'Tem um código de convite? Entre agora.',
                color: isDark ? DraculaColors.green : context.colorGreen,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => _showJoinGroupDialog(context, ref),
              ),

              if (isAdmin && group != null) ...[
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.delete_forever_rounded,
                  title: 'Excluir Grupo "${group.name}"',
                  desc: 'Remove todos os membros e apaga o grupo.',
                  color: isDark ? DraculaColors.red : context.colorRed,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  onTap: () => _confirmDeleteGroup(context, ref, group),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Web Body Layout ────────────────────────────────────────────────────────
  Widget _buildWebBody(
    BuildContext context,
    WidgetRef ref,
    FamilyGroup? group,
    AppUser? user,
    bool isAdmin,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtleColor,
    Color accentColor,
  ) {
    return Row(
      children: [
        const WebSidebar(active: NavSection.settings),
        Expanded(
          child: Column(
            children: [
              const WebTopBar(
                title: 'Gerenciamento de Grupos',
                subtitle: 'Crie, mude, exclua ou convide membros para seus grupos familiares.',
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
                          // Column 1: Groups list and creation actions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (group != null && user != null) ...[
                                  _buildSectionHeader('MEUS GRUPOS', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildUserGroupsList(context, ref, user, group, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                                  const SizedBox(height: 28),
                                ],

                                _buildSectionHeader('AÇÕES DE GRUPO', subtleColor),
                                const SizedBox(height: 12),
                                _buildActionCard(
                                  icon: Icons.add_home_work_rounded,
                                  title: 'Criar Novo Grupo',
                                  desc: 'Crie um novo grupo e convide sua família.',
                                  color: accentColor,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  subtleColor: subtleColor,
                                  onTap: () => _showCreateGroupDialog(context, ref),
                                ),
                                const SizedBox(height: 12),
                                _buildActionCard(
                                  icon: Icons.group_add_rounded,
                                  title: 'Entrar em um Grupo',
                                  desc: 'Tem um código de convite? Entre agora.',
                                  color: isDark ? DraculaColors.green : context.colorGreen,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  subtleColor: subtleColor,
                                  onTap: () => _showJoinGroupDialog(context, ref),
                                ),

                                if (isAdmin && group != null) ...[
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.delete_forever_rounded,
                                    title: 'Excluir Grupo "${group.name}"',
                                    desc: 'Remove todos os membros e apaga o grupo.',
                                    color: isDark ? DraculaColors.red : context.colorRed,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtleColor: subtleColor,
                                    onTap: () => _confirmDeleteGroup(context, ref, group),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Column 2: Invite code & group members list
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (group != null) ...[
                                  _buildSectionHeader('CÓDIGO DE CONVITE', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildInviteCard(context, group.inviteCode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                                  const SizedBox(height: 28),

                                  _buildSectionHeader('MEMBROS DO GRUPO ATUAL', subtleColor),
                                  const SizedBox(height: 12),
                                  _buildMembersList(ref, group, user, isAdmin, isDark, cardColor, borderColor, textColor, subtleColor),
                                ],
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

  // ─── Invite Card ─────────────────────────────────────────────────────────────

  Widget _buildInviteCard(
    BuildContext context,
    String code,
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
        boxShadow: isDark ? [] : context.shadow1,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código de Convite', style: TextStyle(fontSize: 12, color: subtleColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? DraculaColors.surface0 : context.colorBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: isDark ? DraculaColors.cyan : context.colorTextPrimary,
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
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhe este código com quem você quer no grupo.',
            style: TextStyle(fontSize: 12, color: subtleColor),
          ),
        ],
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

  // ─── Members List ────────────────────────────────────────────────────────────

  Widget _buildMembersList(
    WidgetRef ref,
    FamilyGroup group,
    AppUser? currentUser,
    bool isAdmin,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtleColor,
  ) {
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
            final accentColor = isDark ? DraculaColors.orange : context.colorOrange;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? DraculaColors.surface1 : context.colorBackground,
                  child: Text(
                    user.name?[0].toUpperCase() ?? '?',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Text(user.name ?? 'Membro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    if (isCreator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('👑 Admin', style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(user.email, style: TextStyle(fontSize: 11, color: subtleColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelf)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? DraculaColors.green : context.colorGreen).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Você', style: TextStyle(color: isDark ? DraculaColors.green : context.colorGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    if (isAdmin && !isSelf)
                      IconButton(
                        icon: const Icon(Icons.person_remove_rounded, size: 20),
                        color: isDark ? DraculaColors.red : context.colorRed,
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

  // ─── User Groups List ────────────────────────────────────────────────────────

  Widget _buildUserGroupsList(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    FamilyGroup? activeGroup,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtleColor,
    Color accentColor,
  ) {
    final greenColor = isDark ? DraculaColors.green : context.colorGreen;
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
                color: isActive ? greenColor.withValues(alpha: 0.08) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? greenColor : borderColor, width: isActive ? 2 : 1),
              ),
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.group_outlined,
                  color: isActive ? greenColor : subtleColor,
                ),
                title: Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? greenColor : textColor)),
                subtitle: Text('${group.memberIds.length} membro(s)', style: TextStyle(fontSize: 11, color: subtleColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: greenColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Ativo', style: TextStyle(color: greenColor, fontSize: 11, fontWeight: FontWeight.bold)),
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
                        child: Text('Ativar', style: TextStyle(color: accentColor)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                      color: isDark ? DraculaColors.red : context.colorRed,
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

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Novo Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do Grupo', hintText: 'Ex: Família Silva'),
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
          decoration: const InputDecoration(labelText: 'Código de Convite', hintText: 'Ex: A1B2C3'),
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
        content: Text('Você tem certeza que quer sair do grupo "${group.name}"?\n\nVocê perderá acesso às listas e ao histórico de preços deste grupo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair do Grupo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (confirmed) await ref.read(groupControllerProvider.notifier).leaveGroup(group.id);
  }

  Future<void> _confirmRemoveMember(BuildContext context, WidgetRef ref, FamilyGroup group, AppUser member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover Membro', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover ${member.name} do grupo "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (confirmed) await ref.read(groupControllerProvider.notifier).removeMember(group.id, member.id);
  }

  Future<void> _confirmDeleteGroup(BuildContext context, WidgetRef ref, FamilyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text('Atenção: Você está prestes a excluir o grupo "${group.name}".\n\nIsso removerá todos os membros e apagará o grupo permanentemente. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Grupo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (confirmed) await ref.read(groupControllerProvider.notifier).deleteGroup(group.id);
  }
}
