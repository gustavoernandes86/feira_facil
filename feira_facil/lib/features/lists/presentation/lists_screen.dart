import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/presentation/widgets/comparison_setup_modal.dart';
import 'package:feira_facil/features/lists/presentation/savings_screen.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:feira_facil/features/notifications/presentation/notifications_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/list_card.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  Future<void> _showComparisonSetup(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<ComparisonSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComparisonSetupModal(),
    );
    
    if (result == null || !context.mounted) return;
    
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;
    
    final repo = ref.read(fairListsRepositoryProvider);
    final itemsSnapshot = await repo.listItemsStream(groupId, result.selectedList.id).first;
    
    if (!context.mounted) return;
    
    context.pushNamed(
      RouteNames.listCompare,
      extra: {
        'fairList': result.selectedList,
        'items': itemsSnapshot,
        'marketIds': result.selectedMarkets.map((m) => m.id).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escutar notificações não lidas para mostrar um toast
    ref.listen(unreadNotificationsProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final currentCount = next.value!.length;
        final previousCount = previous?.value?.length ?? 0;
        
        if (currentCount > previousCount) {
          final latest = next.value!.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${latest.title}: ${latest.body}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.colorGreenDark,
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/notifications');
                },
              ),
            ),
          );
        }
      }
    });

    final userProfile = ref.watch(currentUserProfileProvider).value;
    final group = ref.watch(currentGroupStreamProvider).value;
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsyncValue = groupId != null ? ref.watch(fairListsStreamProvider(groupId)) : const AsyncValue<List<FairList>>.loading();
    final savingsAsync = groupId != null
        ? ref.watch(savingsSummaryProvider(groupId))
        : const AsyncValue<SavingsSummary>.loading();
    final activeFeira = groupId != null ? ref.watch(activeFeiraProvider(groupId)) : null;

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: CustomScrollView(
        slivers: [
          // Custom Dashboard Header
          SliverToBoxAdapter(
            child: _buildDashboardHeader(context, userProfile, group, ref),
          ),

          // Status Cards section
          SliverToBoxAdapter(
            child: _buildStatusSection(context, listsAsyncValue, savingsAsync),
          ),

          // Quick Actions grid
          SliverToBoxAdapter(
            child: _buildQuickActions(context, ref),
          ),

          // Active Shopping Trip (Feira em andamento)
          if (activeFeira != null) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.local_grocery_store_rounded, color: context.colorOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Feira em andamento',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colorOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: ListCard(list: activeFeira.list),
              ),
            ),
          ],

          // Recent Lists Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Suas Listas', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colorOrange,
                    fontWeight: FontWeight.bold,
                  )),
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
      decoration: BoxDecoration(
        color: context.isDark ? context.colorGreenDark : context.colorGreen,
        borderRadius: const BorderRadius.only(
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
                  _notificationIcon(context, ref),
                  const SizedBox(width: 12),
                  _headerIcon(Icons.settings_outlined, onTap: () => context.push('/settings')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null 
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) 
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null 
                    ? const Text('👤', style: TextStyle(fontSize: 24)) 
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olá, ${user?.name?.split(' ').first ?? 'visitante'}', style: const TextStyle(
                    fontSize: 14, color: Colors.white70
                  )),
                  GestureDetector(
                    onTap: () => context.push('/group-management'),
                    child: Row(
                      children: [
                        Text(group?.name ?? 'Sua Família', style: GoogleFonts.fraunces(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white
                        )),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Como vamos economizar hoje?',
            style: GoogleFonts.fraunces(
              fontSize: 28,
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

  Widget _notificationIcon(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final unreadCount = unreadAsync.value?.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _headerIcon(Icons.notifications_none_rounded,
            onTap: () => context.push('/notifications')),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: context.colorRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.isDark ? context.colorGreenDark : context.colorGreen,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, AsyncValue<List<FairList>> listsAsync, AsyncValue<SavingsSummary> savingsAsync) {
    final savings = savingsAsync.value;
    final savingsStr = savings != null && savings.totalSaved > 0
        ? 'R\$ ${savings.totalSaved.toStringAsFixed(2).replaceAll(".", ",")}'
        : 'R\$ 0,00';
    final savingsSub = savings != null && savings.totalSaved > 0
        ? '${savings.lists.length} compra${savings.lists.length != 1 ? 's' : ''}'
        : 'Total acumulado';

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
            context.colorGreen,
            Icons.format_list_bulleted,
          ),
          _statusCard(
            context,
            '💰 Economia',
            savingsStr,
            savingsSub,
            context.colorOrange,
            Icons.trending_up,
            onTap: () => context.pushNamed(RouteNames.savings),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context, String label, String val, String sub, Color color, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.shadow2,
          border: Border.all(color: context.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.withOpacity(0.6), size: 20),
            Spacer(),
            Text(label, style: TextStyle(fontSize: 11, color: context.colorTextTertiary, fontWeight: FontWeight.bold)),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colorTextPrimary)),
            Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
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
                child: _actionTile(
                  context, 
                  '🏷️', 
                  'Nova Lista', 
                  'Criar lista agora', 
                  context.isDark ? context.colorGreenDark : context.colorOrangeLight, 
                  () => _showCreateListDialog(context, ref)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionTile(
                  context, 
                  '🏪', 
                  'Mercados', 
                  'Catálogo de preços', 
                  context.isDark ? context.colorGreenDark : context.colorGreenLight, 
                  () => context.push('/markets')
                ),
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
                  context.isDark ? context.colorGreenDark : const Color(0xFFFFE0B2),
                  () => context.pushNamed(RouteNames.suggestedPurchases),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionTile(
                  context,
                  '💚',
                  'Minha Economia',
                  'Veja quanto poupou',
                  context.isDark ? context.colorGreenDark : context.colorGreenLight,
                  () => context.pushNamed(RouteNames.savings),
                ),
              ),
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
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colorTextPrimary)),
            Text(sub, style: TextStyle(fontSize: 11, color: context.colorTextSecondary)),
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
      child: ListCard(list: list),
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
                        activeColor: context.colorGreen,
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
                      color: context.colorGreen,
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
            Text(
              'Crie uma lista (ex: "Compra do Mês", "Churrasco") para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colorTextSecondary),
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
                backgroundColor: context.isDark ? context.colorGreenDark : context.colorGreen,
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
