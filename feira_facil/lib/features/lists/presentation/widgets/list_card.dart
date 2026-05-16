import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../../core/providers/user_providers.dart';
import '../../domain/fair_list.dart';
import '../../domain/list_item.dart';
import '../fair_lists_controller.dart';
import 'package:feira_facil/features/items/domain/price.dart';
import 'package:feira_facil/features/items/presentation/prices_controller.dart';

class ListCard extends ConsumerWidget {
  final FairList list;

  const ListCard({
    super.key,
    required this.list,
  });

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

  double _calculateTotalCost(List<ListItem> items, List<Price>? allPrices, {bool markedOnly = true}) {
    double total = 0.0;
    for (final item in items) {
      if (!markedOnly || item.marked) {
        final price = _getItemPrice(item, allPrices);
        if (price != null) {
          total += price.calculateBestPrice(item.plannedQuantity);
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    if (groupId == null) return const SizedBox.shrink();

    // Stream list items to display progress and item counts
    final itemsAsync = ref.watch(
      listItemsStreamProvider((groupId: groupId, listId: list.id)),
    );

    // Watch prices if the list is suggested to show cost accumulation re-actively
    final allPricesAsync = list.isSuggested
        ? ref.watch(allPricesProvider(groupId))
        : const AsyncValue<List<Price>>.data([]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: context.shadow2,
        border: Border.all(color: context.colorBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/lists/${list.id}', extra: list),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Lead visual decoration (Shopping Basket)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getLeadingBgColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          list.isSuggested
                              ? Icons.local_grocery_store_rounded
                              : Icons.shopping_basket_rounded,
                          color: _getLeadingIconColor(context),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colorTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _buildBudgetAndInfo(context),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress indicator section
                  itemsAsync.when(
                    data: (items) {
                      final allPrices = allPricesAsync.value;
                      return _buildProgressSection(context, items, allPrices);
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, __) => _buildErrorProgress(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getLeadingBgColor(BuildContext context) {
    if (list.isSuggested) {
      return context.isDark ? context.colorOrange.withValues(alpha: 0.15) : const Color(0xFFFFE0B2);
    }
    switch (list.status) {
      case 'em_compra':
        return context.colorOrangeLight;
      case 'concluida':
        return context.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100;
      default:
        return context.colorGreenLight;
    }
  }

  Color _getLeadingIconColor(BuildContext context) {
    if (list.isSuggested) {
      return context.colorOrange;
    }
    switch (list.status) {
      case 'em_compra':
        return context.colorOrange;
      case 'concluida':
        return context.colorTextTertiary;
      default:
        return context.colorGreen;
    }
  }

  Widget _buildBudgetAndInfo(BuildContext context) {
    final List<Widget> details = [];

    if (list.isSuggested && list.totalCost != null && list.worstCaseCost != null) {
      final savings = list.worstCaseCost! - list.totalCost!;
      if (savings > 0) {
        final formattedSavings = savings.toStringAsFixed(2).replaceAll('.', ',');
        details.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_down_rounded, size: 14, color: context.colorOrange),
              const SizedBox(width: 4),
              Text(
                'Economia: R\$ $formattedSavings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colorOrange,
                ),
              ),
            ],
          ),
        );
      }
    } else if (list.budget != null && list.budget! > 0) {
      final formattedBudget = list.budget!.toStringAsFixed(2).replaceAll('.', ',');
      details.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 13, color: context.colorTextSecondary),
            const SizedBox(width: 4),
            Text(
              'R\$ $formattedBudget',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colorTextSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      details.add(
        Text(
          'Toque para gerenciar',
          style: TextStyle(
            fontSize: 12,
            color: context.colorTextTertiary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: details,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    String text = 'Ativa';
    Color bg = context.colorGreenLight;
    Color fg = context.colorGreen;

    if (list.isSuggested) {
      text = 'Feira';
      bg = context.isDark ? context.colorOrange.withValues(alpha: 0.15) : const Color(0xFFFFE0B2);
      fg = context.colorOrange;
    }

    switch (list.status) {
      case 'em_compra':
        text = 'No Mercado';
        bg = context.colorOrangeLight;
        fg = context.colorOrange;
        break;
      case 'concluida':
        text = 'Concluída';
        bg = context.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100;
        fg = context.colorTextTertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    List<ListItem> items,
    List<Price>? allPrices,
  ) {
    if (items.isEmpty) {
      return Text(
        'Nenhum item adicionado ainda',
        style: TextStyle(
          fontSize: 11,
          color: context.colorTextTertiary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final totalItems = items.length;
    final markedItems = items.where((item) => item.marked).length;
    final progress = totalItems > 0 ? markedItems / totalItems : 0.0;
    final percent = (progress * 100).toInt();

    Color progressColor = context.colorGreen;
    if (list.status == 'em_compra') {
      progressColor = context.colorOrange;
    } else if (list.status == 'concluida') {
      progressColor = context.colorTextSecondary;
    }

    String progressText;
    if (list.isSuggested) {
      final markedCost = _calculateTotalCost(items, allPrices, markedOnly: true);
      final totalCost = _calculateTotalCost(items, allPrices, markedOnly: false);
      final formattedMarked = markedCost.toStringAsFixed(2).replaceAll('.', ',');
      final formattedTotal = totalCost.toStringAsFixed(2).replaceAll('.', ',');
      progressText = 'R\$ $formattedMarked de R\$ $formattedTotal';
    } else {
      progressText = '$markedItems de $totalItems itens pegos';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progressText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colorTextSecondary,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(100),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorProgress(BuildContext context) {
    return Text(
      'Erro ao carregar progresso',
      style: TextStyle(
        fontSize: 11,
        color: context.colorRed,
      ),
    );
  }
}
