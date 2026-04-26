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
import 'package:feira_facil/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class MarketDetailScreen extends ConsumerStatefulWidget {
  final Market market;
  const MarketDetailScreen({super.key, required this.market});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  FairList? _selectedList;

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsync = groupId != null ? ref.watch(fairListsStreamProvider(groupId)) : const AsyncValue.loading();
    final pricesAsync = ref.watch(marketPricesStreamProvider(widget.market.id));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.market.name, style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppColors.textBody),
            tooltip: 'Comparar Preços',
            onPressed: () => context.pushNamed(RouteNames.listCompare),
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
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddPriceModal(marketId: widget.market.id),
        ),
        label: const Text('Registrar Avulso', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_chart_rounded),
        backgroundColor: AppColors.textBody,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMarketInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textBody,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [AppColors.shadow2],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.market.address.isNotEmpty ? widget.market.address : 'Endereço não informado',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CATÁLOGO DE PREÇOS',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estes valores serão usados para sugerir onde comprar cada item da sua lista.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Selecione ou crie uma lista para registrar os preços neste mercado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
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
        
        return pricesAsync.when(
          data: (prices) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemPrices = prices.where((p) => p.itemId == item.itemId).toList();
                
                return _ListItemPriceCard(
                  itemName: item.itemId,
                  marketId: widget.market.id,
                  prices: itemPrices,
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
        color: hasPrice ? AppColors.green.withOpacity(0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow1],
        border: Border.all(color: hasPrice ? AppColors.green.withOpacity(0.3) : AppColors.cream2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasPrice ? AppColors.green.withOpacity(0.1) : AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              hasPrice ? Icons.check_circle : Icons.shopping_bag_outlined, 
              color: hasPrice ? AppColors.green : AppColors.textBody
            )
          ),
        ),
        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (hasPrice) ...[
              Text(
                'R\$ ${basePrice.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (brand != null && brand.isNotEmpty)
                Text(
                  'Marca: $brand',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
            ] else ...[
              const Text(
                'Sem preço registrado',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ]
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            hasPrice ? Icons.edit : Icons.add_circle, 
            color: hasPrice ? AppColors.textBody : AppColors.orange, 
            size: 28
          ),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddPriceModal(
              marketId: marketId,
              initialItemName: itemName,
            ),
          ),
        ),
      ),
    );
  }
}
