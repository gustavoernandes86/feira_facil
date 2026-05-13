import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/features/lists/application/list_comparison_service.dart';
import 'package:feira_facil/features/lists/domain/list_item.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:go_router/go_router.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

/// Parâmetros para o provider de comparação por lista
class ListComparisonParams {
  final List<ListItem> items;
  final List<String>? marketIds;

  ListComparisonParams({required this.items, this.marketIds});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListComparisonParams &&
          runtimeType == other.runtimeType &&
          items == other.items &&
          marketIds.toString() == other.marketIds.toString();

  @override
  int get hashCode => items.hashCode ^ marketIds.hashCode;
}

final listComparisonFutureProvider = FutureProvider.autoDispose.family<List<PurchaseStrategy>, ListComparisonParams>((ref, params) async {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return [];
  
  final service = ref.read(listComparisonServiceProvider);
  return service.analyzeList(groupId, params.items, marketIds: params.marketIds);
});

final globalComparisonFutureProvider = FutureProvider.autoDispose<List<PurchaseStrategy>>((ref) async {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return [];
  
  final service = ref.read(listComparisonServiceProvider);
  return service.analyzeAllPricedItems(groupId);
});

class ListComparisonScreen extends ConsumerStatefulWidget {
  final FairList? fairList;
  final List<ListItem>? items;
  final List<String>? marketIds;

  const ListComparisonScreen({
    super.key,
    this.fairList,
    this.items,
    this.marketIds,
  });

  @override
  ConsumerState<ListComparisonScreen> createState() => _ListComparisonScreenState();
}

class _ListComparisonScreenState extends ConsumerState<ListComparisonScreen> {
  bool _isApplying = false;
  List<PurchaseStrategy> _allStrategies = [];

  @override
  Widget build(BuildContext context) {
    final strategiesAsync = widget.fairList != null && widget.items != null
        ? ref.watch(listComparisonFutureProvider(ListComparisonParams(items: widget.items!, marketIds: widget.marketIds)))
        : ref.watch(globalComparisonFutureProvider);

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        backgroundColor: context.colorBackground,
        elevation: 0,
        title: Text(
          'Comparar Preços',
          style: GoogleFonts.fraunces(
            color: context.colorOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: context.colorOrange),
      ),
      body: strategiesAsync.when(
        data: (strategies) {
          if (strategies.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Não há dados suficientes para gerar estratégias. Cadastre mais preços nos mercados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colorTextTertiary, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: strategies.length,
            itemBuilder: (context, index) {
              // Persist strategies so _applyStrategy can compute worstCaseCost
              if (_allStrategies.length != strategies.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _allStrategies = strategies);
                });
              }
              final strategy = strategies[index];
              final isOptimal = index == 0;
              
              return _buildStrategyCard(strategy, isOptimal);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: context.colorOrange)),
        error: (err, stack) => Center(child: Text('Erro ao analisar: $err')),
      ),
    );
  }

  Widget _buildStrategyCard(PurchaseStrategy strategy, bool isOptimal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadow2,
        border: isOptimal ? Border.all(color: context.colorOrange, width: 2) : Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOptimal)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.colorOrange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Text(
                'MELHOR CUSTO-BENEFÍCIO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colorTextBody,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strategy.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Custo Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custo Projetado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.colorTextTertiary,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${strategy.totalCost.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.colorGreen,
                          ),
                        ),
                      ],
                    ),
                    if (strategy.missingItemsCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: context.colorRed),
                            const SizedBox(width: 4),
                            Text(
                              'Faltam ${strategy.missingItemsCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.colorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                
                // Market Summaries
                Text(
                  'RESUMO DE COMPRA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.colorTextTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...strategy.marketSummaries.map((ms) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colorBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.storefront, color: context.colorOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ms.marketName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${ms.itemsCount} itens',
                              style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$ ${ms.cost.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colorTextBody,
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : () => _applyStrategy(strategy),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isOptimal 
                          ? (context.isDark ? context.colorGreenDark : context.colorGreen) 
                          : (context.isDark ? context.colorBackground : context.colorTextBody),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isApplying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Gerar Compra Sugerida',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Future<void> _applyStrategy(PurchaseStrategy strategy) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;
    
    final userId = ref.read(currentUserProfileProvider).value?.id ?? '';
    final listName = widget.fairList?.name ?? 'Lista';
    
    final baseName = 'Compra Sugerida - $listName - ${DateTime.now().day}/${DateTime.now().month}';
    
    final controller = TextEditingController(text: baseName);
    final chosenName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome da Compra Sugerida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nome da lista',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: context.colorTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: context.isDark ? context.colorGreenDark : context.colorGreen),
              child: const Text('Continuar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (chosenName == null) return;
    
    final finalName = chosenName.isEmpty ? baseName : chosenName;

    setState(() => _isApplying = true);
    
    try {
      final existingLists = await ref.read(fairListsRepositoryProvider).getSuggestedListsByBaseName(groupId, finalName);
      
      String nameToCreate = finalName;
      
      if (existingLists.isNotEmpty) {
        if (!mounted) return;
        final result = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Compra Sugerida já existe'),
              content: Text('Você já criou uma compra sugerida hoje.\nO que deseja fazer?'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'nova'),
                  child: Text('Criar Nova', style: TextStyle(color: context.colorOrange)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'sobrepor'),
                  child: Text('Sobrepor', style: TextStyle(color: context.colorRed)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'ir'),
                  style: ElevatedButton.styleFrom(backgroundColor: context.isDark ? context.colorGreenDark : context.colorGreen),
                  child: const Text('Ir para ela', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );

        if (result == null) {
          if (mounted) setState(() => _isApplying = false);
          return;
        }

        existingLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = existingLists.first;

        if (result == 'ir') {
          if (mounted) setState(() => _isApplying = false);
          if (mounted) {
            context.pushReplacementNamed(
              RouteNames.listDetails,
              pathParameters: {'id': latest.id},
              extra: latest,
            );
          }
          return;
        } else if (result == 'sobrepor') {
          await ref.read(fairListsRepositoryProvider).deleteList(groupId: groupId, listId: latest.id);
          nameToCreate = latest.name;
        } else if (result == 'nova') {
          int maxSuffix = 1;
          for (final l in existingLists) {
            if (l.name == finalName) {
              if (1 > maxSuffix) maxSuffix = 1;
            } else if (l.name.startsWith('$finalName - ')) {
              final suffixStr = l.name.replaceFirst('$finalName - ', '');
              final suffix = int.tryParse(suffixStr);
              if (suffix != null && suffix >= maxSuffix) {
                maxSuffix = suffix;
              }
            }
          }
          nameToCreate = '$finalName - ${maxSuffix + 1}';
        }
      }

      // Usa os itens da lista selecionada diretamente (preserva quantidades)
      final items = widget.items ?? [];

      // Calcula o pior cenário (maior custo entre todas as estratégias)
      final worstCaseCost = _allStrategies.isNotEmpty
          ? _allStrategies.map((s) => s.totalCost).reduce((a, b) => a > b ? a : b)
          : null;

      final newListId = await ref.read(fairListsRepositoryProvider).createListFromStrategy(
        groupId: groupId,
        name: nameToCreate,
        userId: userId,
        itemMarketMapping: strategy.itemMarketMapping,
        items: items,
        totalCost: strategy.totalCost,
        worstCaseCost: worstCaseCost,
      );
      
      if (mounted) {
        context.pushReplacementNamed(RouteNames.suggestedPurchases);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: context.colorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}
