import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_repository.dart';
import '../domain/family_group.dart';
import 'group_controller.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(currentGroupStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
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
    final textColor = isDark ? DraculaColors.foreground : context.colorTextBody;
    final subtleColor = isDark ? DraculaColors.comment : context.colorTextSecondary;
    final accentColor = isDark ? DraculaColors.orange : context.colorOrange;

    return Scaffold(
      backgroundColor: bgColor,
      body: groupAsync.when(
        data: (group) {
          final user = userProfileAsync.value;
          final isAdmin = user != null && group != null && group.createdBy == user.id;

          return Column(
            children: [
              // Header
              _buildHeader(context, isDark, accentColor),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [

                    // ── Seção: Aparência ────────────────────────────────────
                    _buildSectionHeader('APARÊNCIA', subtleColor),
                    const SizedBox(height: 12),
                    _buildThemeCard(context, ref, themeMode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                    const SizedBox(height: 32),

                    // ── Seção: Grupo ────────────────────────────────────────
                    _buildSectionHeader('GRUPO FAMILIAR', subtleColor),
                    const SizedBox(height: 12),

                    if (group != null) ...[
                      _buildInviteCard(context, group.inviteCode, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                      const SizedBox(height: 16),
                      _buildSectionHeader('MEMBROS', subtleColor),
                      const SizedBox(height: 12),
                      _buildMembersList(ref, group, user, isAdmin, isDark, cardColor, borderColor, textColor, subtleColor),
                      const SizedBox(height: 24),
                    ],

                    // ── Ações de Grupo ──────────────────────────────────────
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

                    if (group != null && user != null) ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('MEUS GRUPOS', subtleColor),
                      const SizedBox(height: 12),
                      _buildUserGroupsList(context, ref, user, group, isDark, cardColor, borderColor, textColor, subtleColor, accentColor),
                    ],

                    if (isAdmin && group != null) ...[
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.delete_forever_rounded,
                        title: 'Excluir Grupo "${group.name}"',
                        desc: 'Remove todos os membros e apaga o grupo permanentemente.',
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark, Color accentColor) {
    final headerColor = isDark ? DraculaColors.surface0 : context.colorGreen;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Configurações',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
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

  // ─── Theme Card ──────────────────────────────────────────────────────────────

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
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
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : context.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette_outlined, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema Visual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    Text('Escolha entre claro e escuro (Dracula)', style: TextStyle(fontSize: 12, color: subtleColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _themeOption(
                label: 'Claro',
                icon: Icons.light_mode_rounded,
                selected: themeMode == ThemeMode.light,
                color: context.colorOrange,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'Escuro',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == ThemeMode.dark,
                color: isDark ? DraculaColors.purple : context.colorGreen,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'Sistema',
                icon: Icons.brightness_auto_rounded,
                selected: themeMode == ThemeMode.system,
                color: subtleColor,
                textColor: textColor,
                subtleColor: subtleColor,
                onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
              ),
            ],
          ),
          if (themeMode == ThemeMode.dark) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DraculaColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DraculaColors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🧛', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tema Dracula ativo — baseado no tema do VS Code',
                      style: TextStyle(fontSize: 12, color: isDark ? DraculaColors.purple : context.colorTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required Color textColor,
    required Color subtleColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : subtleColor.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : subtleColor, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : subtleColor,
              )),
            ],
          ),
        ),
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
                      color: isDark ? DraculaColors.cyan : context.colorTextBody,
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
