import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/items/domain/price.dart';
import 'package:feira_facil/features/markets/domain/market.dart';
import 'package:feira_facil/features/markets/presentation/market_prices_controller.dart';
import 'package:feira_facil/features/markets/presentation/widgets/add_price_modal.dart';
import 'package:feira_facil/features/markets/presentation/widgets/market_list_selector.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/groups/presentation/group_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/lists/domain/list_item.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/presentation/widgets/comparison_setup_modal.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class MarketDetailScreen extends ConsumerStatefulWidget {
  final Market market;
  const MarketDetailScreen({super.key, required this.market});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  FairList? _selectedList;

  Future<void> _showComparisonSetup() async {
    final result = await showModalBottomSheet<ComparisonSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComparisonSetupModal(),
    );
    
    if (result == null || !mounted) return;
    
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;
    
    final repo = ref.read(fairListsRepositoryProvider);
    final itemsSnapshot = await repo.listItemsStream(groupId, result.selectedList.id).first;
    
    if (!mounted) return;
    
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
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsync = groupId != null ? ref.watch(fairListsStreamProvider(groupId)) : const AsyncValue.loading();
    final pricesAsync = ref.watch(marketPricesStreamProvider(widget.market.id));

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        title: Text(widget.market.name, style: GoogleFonts.fraunces(
          fontWeight: FontWeight.bold,
          color: context.colorTextPrimary,
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: context.colorTextPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: context.colorTextPrimary),
            tooltip: 'Comparar Preços',
            onPressed: () => _showComparisonSetup(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMarketInfo(),
          if (groupId != null && listsAsync is AsyncData)
            Builder(
              builder: (context) {
                final lists = listsAsync.value!;
                
                // Seleciona a primeira lista por padrão se nenhuma estiver selecionada
                if (_selectedList == null && lists.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedList = lists.first;
                      });
                    }
                  });
                }
                
                return MarketListSelector(
                  lists: lists,
                  selectedList: _selectedList,
                  onListSelected: (list) {
                    setState(() {
                      _selectedList = list;
                    });
                  },
                );
              },
            )
          else
             const Center(child: CircularProgressIndicator()),
          
          Expanded(
            child: _selectedList == null
                ? _buildEmptyState(context)
                : _buildListItems(context, groupId!, _selectedList!.id, pricesAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedList == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecione uma lista primeiro para adicionar um produto avulso.')),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddPriceModal(
              marketId: widget.market.id,
              groupId: groupId,
              listId: _selectedList?.id,
            ),
          );
        },
        label: const Text('Registrar Avulso', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_chart_rounded),
        backgroundColor: context.isDark ? context.colorGreenDark : context.colorTextPrimary,
        foregroundColor: context.isDark ? Colors.white : Colors.white,
      ),
    );
  }

  Widget _buildMarketInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.shadow2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: context.colorOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.market.address.isNotEmpty ? widget.market.address : 'Endereço não informado',
                  style: TextStyle(color: context.colorTextSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'CATÁLOGO DE PREÇOS',
            style: TextStyle(
              color: context.colorOrange,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estes valores serão usados para sugerir onde comprar cada item da sua lista.',
            style: TextStyle(color: context.colorTextSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏷️', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          Text(
            'Nenhuma lista selecionada',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Selecione ou crie uma lista para registrar os preços neste mercado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colorTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItems(BuildContext context, String groupId, String listId, AsyncValue<List<Price>> pricesAsync) {
    final itemsAsync = ref.watch(listItemsStreamProvider((groupId: groupId, listId: listId)));
    
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Esta lista está vazia.'));
        }

        // Agrupar itens por categoria
        final Map<String, List<ListItem>> groupedItems = {};
        for (final item in items) {
          final cat = item.category.isEmpty ? 'Outros' : item.category;
          groupedItems.putIfAbsent(cat, () => []).add(item);
        }
        
        final categories = groupedItems.keys.toList()..sort();
        
        return pricesAsync.when(
          data: (prices) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: categories.length,
              itemBuilder: (context, catIndex) {
                final category = categories[catIndex];
                final categoryItems = groupedItems[category]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: context.colorOrange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: context.colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...categoryItems.map((item) {
                      final itemPrices = prices.where((p) => p.itemId == item.itemId).toList();
                      return _ListItemPriceCard(
                        itemName: item.itemId,
                        marketId: widget.market.id,
                        prices: itemPrices,
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro ao carregar preços: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro ao carregar itens: $err')),
    );
  }
}

class _ListItemPriceCard extends ConsumerWidget {
  final String itemName;
  final String marketId;
  final List<Price> prices;
  
  const _ListItemPriceCard({
    required this.itemName,
    required this.marketId,
    required this.prices,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPrice = prices.isNotEmpty;
    // Pega o preço mais recente (assumindo que a lista já vem ordenada ou pegamos o último)
    final bestPriceRecord = hasPrice ? prices.first : null;
    final basePrice = bestPriceRecord?.tiers.isNotEmpty == true 
        ? bestPriceRecord!.tiers.first.pricePerUnit 
        : 0.0;
    final brand = bestPriceRecord?.brand;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasPrice ? context.colorGreen.withOpacity(0.05) : context.colorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadow1,
        border: Border.all(color: hasPrice ? context.colorGreen.withOpacity(0.3) : context.colorBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasPrice ? context.colorGreen.withOpacity(0.1) : context.colorBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              hasPrice ? Icons.check_circle : Icons.shopping_bag_outlined, 
              color: hasPrice ? context.colorGreen : context.colorTextPrimary
            )
          ),
        ),
        title: Text(itemName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (hasPrice) ...[
              Text(
                'R\$ ${basePrice.toStringAsFixed(2)}',
                style: TextStyle(color: context.colorOrange, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (brand != null && brand.isNotEmpty)
                Text(
                  'Marca: $brand',
                  style: TextStyle(color: context.colorTextTertiary, fontSize: 12),
                ),
            ] else ...[
              Text(
                'Sem preço registrado',
                style: TextStyle(color: context.colorTextSecondary, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ]
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            hasPrice ? Icons.edit : Icons.add_circle, 
            color: hasPrice ? context.colorTextPrimary : context.colorOrange, 
            size: 28
          ),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddPriceModal(
              marketId: marketId,
              initialItemName: itemName,
              initialPrice: bestPriceRecord,
            ),
          ),
        ),
      ),
    );
  }
}
