import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/feira_repository.dart';
import '../domain/feira.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/user_providers.dart';

class FeirasScreen extends ConsumerWidget {
  const FeirasScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
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
                decoration: const InputDecoration(
                  labelText: 'Nome do Mercado',
                  hintText: 'Ex: Atacadão, Assaí...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => marketName = val,
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Orçamento Limite (Opcional)',
                  hintText: 'Ex: 500',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => budget = double.tryParse(val) ?? 0,
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feirasAsyncValue = ref.watch(groupFeirasProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(width: 12),
                const Text(
                  'Minhas Feiras',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'Meus Mercados',
                onPressed: () => context.push('/markets'),
              ),
              IconButton(
                icon: const Icon(Icons.group_outlined),
                tooltip: 'Gestão do Grupo',
                onPressed: () => context.push('/group-management'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
          feirasAsyncValue.when(
            data: (feiras) {
              if (feiras.isEmpty) {
                return SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.green.withOpacity(0.15)),
                        const SizedBox(height: 24),
                        const Text(
                          'Sua despensa está esperando!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie sua primeira lista de feira tocando no botão verde no canto da tela.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final feira = feiras[index];
                      final progress = feira.itemsCount > 0 
                        ? feira.checkedItemsCount / feira.itemsCount 
                        : 0.0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.go('/feiras/${feira.id}', extra: feira),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            feira.marketName ?? 'Feira s/ Nome',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${feira.date.day}/${feira.date.month}/${feira.date.year}',
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.shopping_bag, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progresso: ${(progress * 100).toInt()}%',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${feira.checkedItemsCount}/${feira.itemsCount} itens',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress == 1.0 ? Colors.blue : Colors.green,
                                    ),
                                  ),
                                ),
                                if (feira.budget > 0) ...[
                                  const SizedBox(height: 16),
                                  Builder(
                                    builder: (context) {
                                      final budgetProgress = (feira.totalSpent / feira.budget).clamp(0.0, 1.0);
                                      final percent = (feira.totalSpent / feira.budget * 100);
                                      Color budgetColor = Colors.blue;
                                      if (percent >= 90) budgetColor = Colors.red;
                                      else if (percent >= 75) budgetColor = Colors.orange;

                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Meta: R\$ ${feira.budget.toStringAsFixed(0)}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '${percent.toStringAsFixed(0)}%',
                                                style: TextStyle(fontSize: 11, color: budgetColor, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: budgetProgress,
                                              minHeight: 4,
                                              backgroundColor: budgetColor.withOpacity(0.1),
                                              valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TOTAL ATUAL',
                                          style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.grey),
                                        ),
                                        Text(
                                          'R\$ ${feira.totalSpent.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (feira.estimatedTotal > 0)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'ESTIMADO',
                                            style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.grey),
                                          ),
                                          Text(
                                            'R\$ ${feira.estimatedTotal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14, 
                                              color: Colors.grey.shade600,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: feiras.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Erro ao carregar: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        label: const Text('Nova Feira', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
