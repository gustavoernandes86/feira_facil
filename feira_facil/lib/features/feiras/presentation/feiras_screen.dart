import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feira_repository.dart';
import '../domain/feira.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FeirasScreen extends ConsumerWidget {
  const FeirasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final group = ref.watch(currentGroupStreamProvider).value;
    final feirasAsyncValue = ref.watch(groupFeirasProvider);

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
            child: _buildStatusSection(context, feirasAsyncValue),
          ),

          // Quick Actions grid
          SliverToBoxAdapter(
            child: _buildQuickActions(context),
          ),

          // Recent Lists Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Listas Recentes', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todas', style: TextStyle(color: AppColors.orange)),
                  ),
                ],
              ),
            ),
          ),

          // Recent Lists Content
          feirasAsyncValue.when(
            data: (feiras) {
              if (feiras.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Nenhuma feira iniciada.', style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildFeiraCard(context, feiras[index], ref),
                    childCount: feiras.length > 3 ? 3 : feiras.length,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        label: const Text('Nova Feira', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
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

  Widget _buildStatusSection(BuildContext context, AsyncValue<List<Feira>> feirasAsync) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(top: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _statusCard(
            context, 
            '🛒 Itens pegos', 
            '12/32', 
            '60% concluído', 
            AppColors.green,
            Icons.check_circle_outline
          ),
          _statusCard(
            context, 
            '💰 Orçamento', 
            'R\$ 342', 
            'R\$ 158 restantes', 
            AppColors.orange,
            Icons.account_balance_wallet_outlined
          ),
          _statusCard(
            context, 
            '💎 Economia', 
            'R\$ 42', 
            'Sua melhor marca!', 
            Colors.blue,
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

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _actionTile(context, '🏷️', 'Nova Feira', 'Criar lista agora', AppColors.orangeLT, () => _showCreateDialog(context, null)),
              _actionTile(context, '🏪', 'Mercados', 'Ver os melhores', AppColors.greenLT, () => context.push('/markets')),
              _actionTile(context, '👨‍🍳', 'Dicas de Chef', 'Como economizar', const Color(0xFFE3F2FD), () {}),
              _actionTile(context, '📅', 'Histórico', 'Ver feiras passadas', AppColors.cream2, () {}),
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

  Widget _buildFeiraCard(BuildContext context, Feira feira, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(feira.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteFeira(context, feira),
      onDismissed: (_) {
        ref.read(feiraRepositoryProvider).deleteFeira(feira.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: const [AppColors.shadow2],
          border: Border.all(color: AppColors.cream2),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => context.go('/feiras/${feira.id}', extra: feira),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_basket_rounded, color: AppColors.green),
          ),
          title: Text(feira.marketName ?? 'Feira', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${feira.date.day}/${feira.date.month} • ${feira.itemsCount} itens'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () async {
                  final confirm = await _confirmDeleteFeira(context, feira);
                  if (confirm) {
                    ref.read(feiraRepositoryProvider).deleteFeira(feira.id);
                  }
                },
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteFeira(BuildContext context, Feira feira) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Feira'),
        content: Text('Deseja excluir "${feira.marketName ?? 'esta feira'}" e todos os seus itens?'),
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

  // Reuse original create dialog for now with minimal updates
  Future<void> _showCreateDialog(BuildContext context, WidgetRef? ref) async {
    if (ref == null) return;
    String marketName = '';
    double budget = 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Feira'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do Mercado'),
              onChanged: (val) => marketName = val,
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orçamento', prefixText: 'R\$ '),
              onChanged: (val) => budget = double.tryParse(val) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final groupId = ref.read(currentGroupIdProvider);
              if (groupId == null || marketName.trim().isEmpty) return;
              final newFeira = Feira(
                id: FirebaseFirestore.instance.collection('feiras').doc().id,
                groupId: groupId,
                marketName: marketName,
                date: DateTime.now(),
                budget: budget,
              );
              await ref.read(feiraRepositoryProvider).createFeira(newFeira);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
