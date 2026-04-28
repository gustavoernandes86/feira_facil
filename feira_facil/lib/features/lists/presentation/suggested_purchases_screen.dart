import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SuggestedPurchasesScreen extends ConsumerWidget {
  const SuggestedPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final suggestedListsAsync = groupId != null 
        ? ref.watch(suggestedListsStreamProvider(groupId)) 
        : const AsyncValue<List<FairList>>.loading();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Compras Sugeridas',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: AppColors.orange,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.orange,
      ),
      body: Column(
        children: [
          // Seção de Ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => context.pushNamed(RouteNames.listCompare),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [AppColors.shadow1],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.analytics_outlined, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova Comparação Inteligente',
                            style: GoogleFonts.fraunces(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[900],
                            ),
                          ),
                          Text(
                            'Analise preços e economize agora',
                            style: TextStyle(color: Colors.brown[700]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.brown),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'HISTÓRICO DE SUGESTÕES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: suggestedListsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.orange.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma compra sugerida ainda.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const Text(
                          'Comece uma comparação acima!',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return _SuggestedListCard(list: list);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedListCard extends StatelessWidget {
  final FairList list;

  const _SuggestedListCard({required this.list});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(list.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_cart_outlined, color: Colors.orange),
        ),
        title: Text(
          list.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Gerada em $dateStr'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(
          RouteNames.listDetails,
          pathParameters: {'id': list.id},
          extra: list,
        ),
      ),
    );
  }
}
