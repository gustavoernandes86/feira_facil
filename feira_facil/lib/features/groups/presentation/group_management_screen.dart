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

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(currentGroupStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Nenhum grupo selecionado.'));
          }

          return Column(
            children: [
              PremiumHeader(
                title: group.name,
                subtitle: 'Gerencie os membros e configurações do grupo.',
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    _buildInviteCard(context, group.inviteCode),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('MEMBROS DO GRUPO'),
                    const SizedBox(height: 12),
                    _buildMembersList(ref, group, userProfileAsync.value),
                    
                    const SizedBox(height: 32),
                    if (userProfileAsync.value != null && userProfileAsync.value!.groupIds.length > 1) ...[
                      _buildSectionHeader('TROCAR DE GRUPO'),
                      const SizedBox(height: 12),
                      _buildSwitchGroupAction(context, ref, userProfileAsync.value!),
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
        color: AppColors.textTertiary
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
          const SizedBox(height: 16),
          const Text(
            'Compartilhe este código com as pessoas que você quer que participem da sua feira.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(WidgetRef ref, dynamic group, AppUser? currentUser) {
    return FutureBuilder<List<AppUser>>(
      future: ref.read(userRepositoryProvider).getUsers(group.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        final users = snapshot.data ?? [];
        return Column(
          children: users.map((user) => Container(
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
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)
                ),
              ),
              title: Text(user.name ?? 'Membro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              trailing: currentUser?.id == user.id 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Você', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                : null,
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildSwitchGroupAction(BuildContext context, WidgetRef ref, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cream2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Você participa de outros grupos. Deseja alternar?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showSwitchGroupDialog(context, ref, user),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cream,
              foregroundColor: AppColors.textBody,
              elevation: 0,
            ),
            child: const Text('Alternar Grupo Ativo'),
          ),
        ],
      ),
    );
  }

  void _showSwitchGroupDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Trocar Grupo', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: user.groupIds.length,
            itemBuilder: (context, index) {
              final groupId = user.groupIds[index];
              return ListTile(
                title: Text('Grupo $groupId'),
                onTap: () async {
                  await ref.read(groupRepositoryProvider).switchActiveGroup(user.id, groupId);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
