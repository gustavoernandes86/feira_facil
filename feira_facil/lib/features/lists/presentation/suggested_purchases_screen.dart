import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/presentation/widgets/comparison_setup_modal.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:feira_facil/core/widgets/responsive_wrapper.dart';
import 'package:feira_facil/core/widgets/shared_widgets.dart';
import 'package:feira_facil/core/widgets/web_sidebar.dart';

class SuggestedPurchasesScreen extends ConsumerWidget {
  const SuggestedPurchasesScreen({super.key});

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
    
    // Buscar itens da lista selecionada
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

  Future<void> _showClearHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    List<FairList> lists,
  ) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorBackground,
        title: Text(
          'Limpar Histórico',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: context.colorOrange,
          ),
        ),
        content: Text(
          'Tem certeza que deseja limpar todo o histórico de compras finalizadas? Essa ação não pode ser desfeita.',
          style: TextStyle(color: context.colorTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.colorTextTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller = ref.read(fairListsControllerProvider(groupId).notifier);
      await controller.clearFinishedLists(lists);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Histórico de compras finalizadas limpo com sucesso!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colorGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveWrapper(
      mobile: _buildMobileLayout(context, ref),
      web: _buildWebLayout(context, ref),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final suggestedListsAsync = groupId != null 
        ? ref.watch(suggestedListsStreamProvider(groupId)) 
        : const AsyncValue<List<FairList>>.loading();

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        title: Text(
          'Compras Sugeridas',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: context.colorOrange,
          ),
        ),
        backgroundColor: context.colorBackground,
        elevation: 0,
        foregroundColor: context.colorOrange,
      ),
      body: Column(
        children: [
          // Seção de Ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => _showComparisonSetup(context, ref),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: context.isDark ? null : const LinearGradient(
                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  color: context.isDark ? context.colorOrange.withValues(alpha: 0.15) : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.shadow1,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colorBackground,
                      child: const Icon(Icons.analytics_outlined, color: Colors.orange),
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
                              color: context.isDark ? context.colorOrange : Colors.brown[900],
                            ),
                          ),
                          Text(
                            'Analise preços e economize agora',
                            style: TextStyle(color: context.isDark ? context.colorOrange.withValues(alpha: 0.7) : Colors.brown[700]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: context.isDark ? context.colorOrange : Colors.brown),
                  ],
                ),
              ),
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
                        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.orange.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma compra sugerida ainda.',
                          style: TextStyle(color: context.colorTextSecondary),
                        ),
                        Text(
                          'Comece uma comparação acima!',
                          style: TextStyle(color: context.colorTextTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final activeSuggested = lists.where((l) => l.status != 'concluida').toList();
                final finishedSuggested = lists.where((l) => l.status == 'concluida').toList();

                final List<Widget> children = [];

                if (activeSuggested.isNotEmpty) {
                  children.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.local_grocery_store_outlined, size: 16, color: context.colorTextSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'FEIRAS EM ANDAMENTO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: context.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ));
                  for (final list in activeSuggested) {
                    children.add(_SuggestedListCard(list: list, isFinished: false));
                  }
                  children.add(const SizedBox(height: 16));
                }

                if (finishedSuggested.isNotEmpty) {
                  children.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: context.colorTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'COMPRAS FINALIZADAS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: context.colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _showClearHistoryDialog(context, ref, finishedSuggested);
                          },
                          icon: Icon(Icons.delete_sweep_outlined, size: 16, color: context.colorOrange),
                          label: Text(
                            'Limpar Histórico',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.colorOrange,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ));
                  for (final list in finishedSuggested) {
                    children.add(_SuggestedListCard(list: list, isFinished: true));
                  }
                  children.add(const SizedBox(height: 16));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: children,
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

  // ── Web Layout (Split layout for history and ongoing) ──────────────────────
  Widget _buildWebLayout(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final suggestedListsAsync = groupId != null 
        ? ref.watch(suggestedListsStreamProvider(groupId)) 
        : const AsyncValue<List<FairList>>.loading();

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: Row(
        children: [
          const WebSidebar(active: NavSection.suggested),
          Expanded(
            child: Column(
              children: [
                WebTopBar(
                  title: 'Compras Sugeridas',
                  subtitle: 'Acompanhe as sugestões de compra do grupo baseadas nas melhores ofertas.',
                  actions: [
                    WebActionButton(
                      icon: Icons.analytics_outlined,
                      label: 'Nova Comparação Inteligente',
                      onPressed: () => _showComparisonSetup(context, ref),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWebDashboardPromo(context, ref),
                            const SizedBox(height: 28),
                            suggestedListsAsync.when(
                              data: (lists) {
                                if (lists.isEmpty) {
                                  return _buildWebEmptyState(context, ref);
                                }

                                final activeSuggested = lists.where((l) => l.status != 'concluida').toList();
                                final finishedSuggested = lists.where((l) => l.status == 'concluida').toList();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Column 1: Ongoing suggested purchases
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: context.colorCard,
                                          borderRadius: BorderRadius.circular(AppColors.radiusXl),
                                          border: Border.all(color: context.colorBorder),
                                          boxShadow: context.shadow2,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.local_grocery_store_outlined, size: 20, color: context.colorOrange),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Feiras em Andamento',
                                                  style: GoogleFonts.fraunces(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: context.colorTextPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            if (activeSuggested.isEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(32.0),
                                                child: Center(
                                                  child: Text(
                                                    'Nenhuma feira sugerida em andamento.',
                                                    style: TextStyle(color: context.colorTextTertiary, fontSize: 13),
                                                  ),
                                                ),
                                              )
                                            else
                                              Column(
                                                children: activeSuggested.map((list) {
                                                  return _SuggestedListCard(list: list, isFinished: false);
                                                }).toList(),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Column 2: Completed / Finished suggested history
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: context.colorCard,
                                          borderRadius: BorderRadius.circular(AppColors.radiusXl),
                                          border: Border.all(color: context.colorBorder),
                                          boxShadow: context.shadow2,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.check_circle_outline, size: 20, color: context.colorGreen),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Histórico Concluído',
                                                      style: GoogleFonts.fraunces(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: context.colorTextPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (finishedSuggested.isNotEmpty)
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      _showClearHistoryDialog(context, ref, finishedSuggested);
                                                    },
                                                    icon: Icon(Icons.delete_sweep_outlined, size: 16, color: context.colorOrange),
                                                    label: Text(
                                                      'Limpar Histórico',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.colorOrange,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            if (finishedSuggested.isEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(32.0),
                                                child: Center(
                                                  child: Text(
                                                    'Nenhuma feira finalizada no histórico.',
                                                    style: TextStyle(color: context.colorTextTertiary, fontSize: 13),
                                                  ),
                                                ),
                                              )
                                            else
                                              Column(
                                                children: finishedSuggested.map((list) {
                                                  return _SuggestedListCard(list: list, isFinished: true);
                                                }).toList(),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, _) => Center(
                                child: Text('Erro: $err', style: TextStyle(color: context.colorRed)),
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
      ),
    );
  }

  Widget _buildWebDashboardPromo(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.isDark ? context.colorOrange.withValues(alpha: 0.15) : const Color(0xFFFFECE0),
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: context.colorOrange.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colorOrange.withValues(alpha: 0.12),
            child: Icon(Icons.auto_awesome, color: context.colorOrange, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparação Inteligente e Sugestões Automatizadas',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cruze os preços coletados dos mercados locais e gere listas inteligentes otimizadas por economia de produtos.',
                  style: TextStyle(
                    color: context.colorTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          WebActionButton(
            icon: Icons.analytics_outlined,
            label: 'Comparar Agora',
            onPressed: () => _showComparisonSetup(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildWebEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 64, color: context.colorOrange.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'Nenhuma compra sugerida gerada',
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicie uma nova comparação inteligente para cruzar preços e receber sugestões de compra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colorTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SuggestedListCard extends StatelessWidget {
  final FairList list;
  final bool isFinished;

  const _SuggestedListCard({required this.list, this.isFinished = false});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(list.updatedAt ?? list.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: isFinished
              ? context.colorGreen.withValues(alpha: 0.15)
              : context.colorOrange.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isFinished
                ? context.colorGreen.withValues(alpha: 0.1)
                : context.colorOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFinished ? Icons.check_circle_outline : Icons.shopping_cart_outlined,
            color: isFinished ? context.colorGreen : context.colorOrange,
          ),
        ),
        title: Text(
          list.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.colorTextPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          isFinished ? 'Concluída em $dateStr' : 'Gerada em $dateStr',
          style: TextStyle(color: context.colorTextTertiary, fontSize: 11),
        ),
        trailing: Icon(Icons.chevron_right, color: context.colorTextSecondary, size: 20),
        onTap: () => context.pushNamed(
          RouteNames.listDetails,
          pathParameters: {'id': list.id},
          extra: list,
        ),
      ),
    );
  }
}
