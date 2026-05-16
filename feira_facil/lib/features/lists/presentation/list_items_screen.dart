import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/utils/category_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/lists/domain/list_item.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/markets/presentation/markets_controller.dart';
import 'package:feira_facil/features/markets/domain/market.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/core/utils/unit_utils.dart';
import 'package:feira_facil/features/items/domain/price.dart';
import 'package:feira_facil/features/items/presentation/prices_controller.dart';
import 'package:feira_facil/features/lists/presentation/widgets/comparison_setup_modal.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class ListItemsScreen extends ConsumerStatefulWidget {
  final String listId;
  final FairList? listContext;

  const ListItemsScreen({super.key, required this.listId, this.listContext});

  @override
  ConsumerState<ListItemsScreen> createState() => _ListItemsScreenState();
}

class _ListItemsScreenState extends ConsumerState<ListItemsScreen> {
  String _searchQuery = '';
  final Set<String> _collapsedGroups = {};
  final Set<String> _collapsedCategories = {};

  Price? _getItemPrice(ListItem item, List<Price>? allPrices) {
    if (allPrices == null) return null;
    Price? itemPrice;
    final pricesForItem = allPrices.where((p) => p.itemId == item.itemId).toList();
    if (item.selectedMarketId != null && item.selectedMarketId!.isNotEmpty) {
      final marketPrices = pricesForItem.where((p) => p.marketId == item.selectedMarketId).toList();
      if (marketPrices.isNotEmpty) {
        marketPrices.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
        itemPrice = marketPrices.first;
      }
    }
    
    if (itemPrice == null && pricesForItem.isNotEmpty) {
      pricesForItem.sort((a, b) {
        if (a.tiers.isEmpty) return 1;
        if (b.tiers.isEmpty) return -1;
        return a.tiers.first.pricePerUnit.compareTo(b.tiers.first.pricePerUnit);
      });
      itemPrice = pricesForItem.first;
    }
    return itemPrice;
  }

  double _calculateTotalCost(List<ListItem> items, List<Price>? allPrices) {
    double total = 0.0;
    for (final item in items) {
      if (item.marked) {
        final price = _getItemPrice(item, allPrices);
        if (price != null) {
          total += price.calculateBestPrice(item.plannedQuantity);
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    if (groupId == null) return const Scaffold(body: Center(child: Text('Erro: Nenhum grupo selecionado')));

    final itemsAsync = ref.watch(listItemsStreamProvider((groupId: groupId, listId: widget.listId)));
    final marketsAsync = ref.watch(marketsStreamProvider(groupId));
    final allPricesAsync = ref.watch(allPricesProvider(groupId));

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        backgroundColor: context.isDark ? context.colorGreenDark : context.colorGreen,
        foregroundColor: Colors.white,
        title: Text(widget.listContext?.name ?? 'Lista Base', style: GoogleFonts.fraunces(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        )),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            tooltip: 'Comparar Preços',
            onPressed: () async {
              final items = itemsAsync.value ?? [];
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adicione itens à lista primeiro!')),
                );
                return;
              }
              
              // Mostrar modal de seleção de mercados
              final result = await showModalBottomSheet<ComparisonSetup>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ComparisonSetupModal(),
              );
              
              if (result == null || !context.mounted) return;
              
              context.pushNamed(
                RouteNames.listCompare,
                extra: {
                  'fairList': result.selectedList,
                  'items': items,
                  'marketIds': result.selectedMarkets.map((m) => m.id).toList(),
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Excluir Lista',
            onPressed: () => _confirmDeleteList(context, ref, groupId),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Pesquisar produto...',
                  hintStyle: TextStyle(color: Colors.white54),
                  icon: Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.search, color: Colors.white54, size: 20),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          var filteredItems = items;
          if (_searchQuery.isNotEmpty) {
            filteredItems = items.where((i) => i.itemId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          if (filteredItems.isEmpty) return _buildEmptyState();

          final isSuggested = widget.listContext?.isSuggested ?? false;
          final uniqueMarketIds = filteredItems
              .map((i) => i.selectedMarketId)
              .where((id) => id != null && id.isNotEmpty)
              .toSet();
          final groupByMarket = isSuggested && uniqueMarketIds.length > 1;

          // Agrupar itens
          final groupedItems = <String, List<ListItem>>{};
          
          if (groupByMarket) {
            for (final item in filteredItems) {
              final marketId = item.selectedMarketId;
              final marketName = marketId != null && marketId.isNotEmpty
                  ? (marketsAsync.value?.firstWhere((m) => m.id == marketId, orElse: () => Market(id: '', name: 'Desconhecido', address: '', groupId: groupId, createdBy: '', createdAt: DateTime.now())).name ?? 'Desconhecido')
                  : 'Sem Mercado';
                  
              if (!groupedItems.containsKey(marketName)) {
                groupedItems[marketName] = [];
              }
              groupedItems[marketName]!.add(item);
            }
          } else {
            for (final item in filteredItems) {
              final cat = item.category;
              if (!groupedItems.containsKey(cat)) {
                groupedItems[cat] = [];
              }
              groupedItems[cat]!.add(item);
            }
          }

          final sortedGroups = groupedItems.keys.toList();
          sortedGroups.sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final groupName = sortedGroups[index];
              final groupItems = groupedItems[groupName]!;
              
              // Ordena os itens alfabeticamente dentro do grupo
              groupItems.sort((a, b) => a.itemId.toLowerCase().compareTo(b.itemId.toLowerCase()));
              
              IconData headerIcon;
              Color headerColor;

              if (groupByMarket) {
                headerIcon = Icons.storefront;
                headerColor = context.colorOrange;
              } else {
                final catInfo = AppCategories.firstWhere(
                  (c) => c.name == groupName, 
                  orElse: () => AppCategories.last,
                );
                headerIcon = catInfo.icon;
                headerColor = catInfo.color;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_collapsedGroups.contains(groupName)) {
                          _collapsedGroups.remove(groupName);
                        } else {
                          _collapsedGroups.add(groupName);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4, right: 8),
                      child: Row(
                        children: [
                          Icon(headerIcon, size: 20, color: headerColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              groupName,
                              style: GoogleFonts.fraunces(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.colorTextPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'R\$ ${_calculateTotalCost(groupItems, allPricesAsync.value).toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.colorGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _collapsedGroups.contains(groupName) ? Icons.expand_more : Icons.expand_less,
                            color: context.colorTextTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_collapsedGroups.contains(groupName))
                    if (groupByMarket)
                      ...(() {
                        final catGroups = <String, List<ListItem>>{};
                        for (final item in groupItems) {
                          catGroups.putIfAbsent(item.category, () => []).add(item);
                        }
                        
                        final sortedCats = catGroups.keys.toList()..sort();
                        
                        return sortedCats.expand((catName) {
                          final catItems = catGroups[catName]!;
                          catItems.sort((a, b) => a.itemId.toLowerCase().compareTo(b.itemId.toLowerCase()));
                          final catInfo = AppCategories.firstWhere((c) => c.name == catName, orElse: () => AppCategories.last);
                          
                          final catKey = '${groupName}_$catName';
                          final isCatCollapsed = _collapsedCategories.contains(catKey);

                          return [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isCatCollapsed) {
                                    _collapsedCategories.remove(catKey);
                                  } else {
                                    _collapsedCategories.add(catKey);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(catInfo.icon, size: 16, color: catInfo.color),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        catName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: context.colorTextSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'R\$ ${_calculateTotalCost(catItems, allPricesAsync.value).toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.colorGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isCatCollapsed ? Icons.expand_more : Icons.expand_less,
                                      size: 18,
                                      color: context.colorTextTertiary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isCatCollapsed)
                              ...catItems.map((item) {
                                final market = marketsAsync.value?.firstWhere(
                                  (m) => m.id == item.selectedMarketId,
                                  orElse: () => Market(id: '', name: '', address: '', groupId: groupId, createdBy: '', createdAt: DateTime.now()),
                                );
                                return _buildItemCard(context, item, groupId, catInfo, market, groupByMarket, allPricesAsync.value);
                              }),
                          ];
                        });
                      })()
                    else
                      ...groupItems.map((item) {
                        final market = marketsAsync.value?.firstWhere(
                          (m) => m.id == item.selectedMarketId,
                          orElse: () => Market(id: '', name: '', address: '', groupId: groupId, createdBy: '', createdAt: DateTime.now()),
                        );
                        
                        final catInfo = AppCategories.firstWhere(
                          (c) => c.name == item.category, 
                          orElse: () => AppCategories.last,
                        );

                        return _buildItemCard(context, item, groupId, catInfo, market, groupByMarket, allPricesAsync.value);
                      }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemModal(context, ref, groupId),
        label: const Text('Adicionar Produto', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: context.isDark ? context.colorGreenDark : context.colorTextPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text(
              'Lista Base Vazia',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione produtos que você costuma comprar nesta lista.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colorTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ListItem item, String groupId, CategoryInfo? catInfo, Market? market, bool groupByMarket, List<Price>? allPrices) {

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(fairListsControllerProvider(groupId).notifier).removeItemFromList(
          listId: widget.listId, 
          listItemId: item.id
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.shadow1,
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.marked,
              activeColor: context.colorGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                if (val != null) {
                  ref.read(fairListsControllerProvider(groupId).notifier).toggleItemMarked(
                    listId: widget.listId,
                    listItemId: item.id,
                    marked: val,
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemId,
                    style: TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold, 
                      color: item.marked ? context.colorTextTertiary : context.colorTextPrimary,
                      decoration: item.marked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final itemPrice = _getItemPrice(item, allPrices);

                      if (itemPrice != null) {
                        final cost = itemPrice!.calculateBestPrice(item.plannedQuantity);
                        final unitPrice = itemPrice!.tiers.isNotEmpty ? itemPrice!.tiers.first.pricePerUnit : 0.0;
                        final unitPriceStr = unitPrice.toStringAsFixed(2).replaceAll('.', ',');
                        
                        return Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'R\$ ${cost.toStringAsFixed(2).replaceAll('.', ',')} (R\$ $unitPriceStr / ${itemPrice!.unit.abbreviation})',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colorGreen),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (market != null && market.id.isNotEmpty && !groupByMarket)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.storefront, size: 12, color: context.colorOrange),
                          SizedBox(width: 4),
                          Text(
                            'Comprar no ${market.name}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colorOrange),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.colorBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    if (item.plannedQuantity > 1) {
                      ref.read(fairListsControllerProvider(groupId).notifier).updateItemQuantity(
                        listId: widget.listId, 
                        listItemId: item.id,
                        newQuantity: item.plannedQuantity - 1
                      );
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.plannedQuantity.toString().replaceAll('.0', '')} ${item.unit.abbreviation}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  _qtyBtn(Icons.add, () {
                    ref.read(fairListsControllerProvider(groupId).notifier).updateItemQuantity(
                      listId: widget.listId, 
                      listItemId: item.id,
                      newQuantity: item.plannedQuantity + 1
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: context.colorTextSecondary),
      ),
    );
  }

  void _showAddItemModal(BuildContext context, WidgetRef ref, String groupId) {
    String itemName = '';
    double itemQuantity = 1.0;
    ItemUnit selectedUnit = ItemUnit.un;
    String selectedCategory = AppCategories.first.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                color: context.colorBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Adicionar Produto',
                      style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nome do Produto'),
                      onChanged: (val) => itemName = val,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: AppCategories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.name,
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 20, color: cat.color),
                                  const SizedBox(width: 12),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Quantidade'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                initialValue: '1',
                                onChanged: (val) => itemQuantity = double.tryParse(val.replaceAll(',', '.')) ?? 1.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<ItemUnit>(
                                value: selectedUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unidade',
                                  prefixIcon: Icon(Icons.scale_outlined),
                                ),
                                items: ItemUnit.values.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedUnit = val);
                                },
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (itemName.trim().isEmpty) return;
                        ref.read(fairListsControllerProvider(groupId).notifier).addItemToList(
                          listId: widget.listId, 
                          itemId: itemName.trim(),
                          quantity: itemQuantity,
                          unit: selectedUnit,
                          category: selectedCategory,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Adicionar à Lista'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteList(BuildContext context, WidgetRef ref, String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lista'),
        content: Text('Deseja excluir a lista "${widget.listContext?.name ?? 'Lista'}"?'),
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

    if (confirmed && context.mounted) {
      await ref.read(fairListsControllerProvider(groupId).notifier).deleteList(widget.listId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
