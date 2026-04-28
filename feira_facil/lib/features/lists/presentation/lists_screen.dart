import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/core/router/app_router.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final group = ref.watch(currentGroupStreamProvider).value;
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsyncValue = groupId != null ? ref.watch(fairListsStreamProvider(groupId)) : const AsyncValue<List<FairList>>.loading();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // Custom Dashboard Header
          SliverToBoxAdapter(
            child: _buildDashboardHeader(context, userProfile, group, ref),
          ),

          // Status Cards section
          SliverToBoxAdapter(
            child: _buildStatusSection(context, listsAsyncValue),
          ),

          // Quick Actions grid
          SliverToBoxAdapter(
            child: _buildQuickActions(context, ref),
          ),

          // Recent Lists Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Suas Listas', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ),

          // Lists Content
          listsAsyncValue.when(
            data: (lists) {
              if (lists.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(context, ref),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildListCard(context, lists[index], ref),
                    childCount: lists.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Erro: $err'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context, dynamic user, dynamic group, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo no topo do dashboard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/logo-horizontal-escura.png',
                height: 36,
                fit: BoxFit.contain,
              ),
              Row(
                children: [
                  _headerIcon(Icons.analytics_outlined, onTap: () => context.pushNamed(RouteNames.listCompare)),
                  const SizedBox(width: 12),
                  _headerIcon(Icons.notifications_none_rounded),
                  const SizedBox(width: 12),
                  _headerIcon(Icons.menu_rounded, onTap: () => context.push('/group-management')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Text('👤', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olá, ${user?.name?.split(' ').first ?? 'visitante'}', style: const TextStyle(
                    fontSize: 14, color: Colors.white70
                  )),
                  Text(group?.name ?? 'Sua Família', style: GoogleFonts.fraunces(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white
                  )),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Como vamos\neconomizar hoje?',
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AsyncValue<List<FairList>> listsAsync) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(top: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _statusCard(
            context, 
            '📋 Suas Listas', 
            listsAsync.value?.length.toString() ?? '0', 
            'Listas ativas', 
            AppColors.green,
            Icons.format_list_bulleted
          ),
          _statusCard(
            context, 
            '💰 Economia', 
            'R\$ 42', 
            'Mês atual', 
            AppColors.orange,
            Icons.trending_up
          ),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context, String label, String val, String sub, Color color, IconData icon) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow2],
        border: Border.all(color: AppColors.cream2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 20),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBody)),
          Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionTile(context, '🏷️', 'Nova Lista', 'Criar lista agora', AppColors.orangeLT, () => _showCreateListDialog(context, ref)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionTile(context, '🏪', 'Mercados', 'Catálogo de preços', AppColors.greenLT, () => context.push('/markets')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  context, 
                  '✨', 
                  'Compras Sugeridas', 
                  'Onde está mais barato?', 
                  const Color(0xFFFFE0B2), // Light Amber/Gold
                  () => context.pushNamed(RouteNames.suggestedPurchases),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Placeholder for balance
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, String emoji, String title, String sub, Color bg, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBody)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
            child: const Icon(Icons.shopping_basket_rounded, color: AppColors.green),
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
    bool copyFromBaseList = true; // Default to true

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Lista'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome da Lista (ex: Compra do Mês)'),
                    onChanged: (val) => listName = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: copyFromBaseList,
                        onChanged: (val) {
                          setState(() {
                            copyFromBaseList = val ?? true;
                          });
                        },
                        activeColor: AppColors.green,
                      ),
                      const Expanded(
                        child: Text(
                          'Criar baseado na Lista Básica',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
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
                      copyFromBaseList: copyFromBaseList,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
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
              'Nenhuma Lista Criada',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie uma lista (ex: "Compra do Mês", "Churrasco") para começar.',
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
}
