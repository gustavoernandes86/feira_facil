import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../items/data/prices_repository.dart';
import '../../items/domain/price.dart';
import '../../markets/data/markets_repository.dart';
import '../domain/list_item.dart';

final listComparisonServiceProvider = Provider<ListComparisonService>((ref) {
  final pricesRepo = ref.read(pricesRepositoryProvider);
  final marketsRepo = ref.read(marketsRepositoryProvider);
  return ListComparisonService(pricesRepo, marketsRepo);
});

class StrategyMarketSummary {
  final String marketId;
  final String marketName;
  final double cost;
  final int itemsCount;

  StrategyMarketSummary({
    required this.marketId,
    required this.marketName,
    required this.cost,
    required this.itemsCount,
  });
}

class PurchaseStrategy {
  final String id;
  final String title;
  final String description;
  final double totalCost;
  final int missingItemsCount;
  final List<StrategyMarketSummary> marketSummaries;
  final Map<String, String> itemMarketMapping; // listItem.id -> marketId

  PurchaseStrategy({
    required this.id,
    required this.title,
    required this.description,
    required this.totalCost,
    required this.missingItemsCount,
    required this.marketSummaries,
    required this.itemMarketMapping,
  });
}

class ListComparisonService {
  final PricesRepository _pricesRepo;
  final MarketsRepository _marketsRepo;

  ListComparisonService(this._pricesRepo, this._marketsRepo);

  Future<List<PurchaseStrategy>> analyzeList(String groupId, List<ListItem> items) async {
    if (items.isEmpty) return [];

    // 1. Fetch all markets
    final markets = await _marketsRepo.getMarkets(groupId);
    if (markets.isEmpty) return [];
    
    final marketMap = {for (var m in markets) m.id: m};

    // 2. Fetch prices for all items
    // Since items could be many, we fetch all prices in the group and filter locally 
    // to avoid N+1 queries. Or we can just fetch prices for the specific items.
    final itemIds = items.map((i) => i.itemId).toSet().toList();
    
    // This fetches all prices in the group. If the group is huge, this might be slow, 
    // but typically a family group has < 1000 prices.
    final allPrices = await _pricesRepo.getAllPrices(groupId);
    
    // Group prices by itemId -> MarketId -> Price
    final priceMap = <String, Map<String, Price>>{};
    for (var p in allPrices) {
      if (itemIds.contains(p.itemId)) {
        priceMap.putIfAbsent(p.itemId, () => {})[p.marketId] = p;
      }
    }

    final strategies = <PurchaseStrategy>[];

    // STRATEGY: SINGLE MARKET
    for (final market in markets) {
      double totalCost = 0;
      int missing = 0;
      final mapping = <String, String>{};
      int foundItems = 0;

      for (final listItem in items) {
        final itemPrices = priceMap[listItem.itemId];
        final marketPrice = itemPrices?[market.id];

        if (marketPrice != null) {
          // Só calcula se as unidades forem compatíveis ou se não houver unidade definida no preço
          // Para simplificar: se as unidades forem diferentes, ignoramos este preço para este cálculo
          if (marketPrice.unit == listItem.unit) {
            totalCost += marketPrice.calculateBestPrice(listItem.plannedQuantity);
            mapping[listItem.id] = market.id;
            foundItems++;
          } else {
            missing++;
          }
        } else {
          missing++;
        }
      }

      if (foundItems > 0) {
        strategies.add(PurchaseStrategy(
          id: 'single_${market.id}',
          title: 'Tudo no ${market.name}',
          description: missing == 0 
            ? 'Praticidade de comprar tudo no mesmo lugar.'
            : 'Faltam $missing itens neste mercado.',
          totalCost: totalCost,
          missingItemsCount: missing,
          marketSummaries: [
            StrategyMarketSummary(
              marketId: market.id,
              marketName: market.name,
              cost: totalCost,
              itemsCount: foundItems,
            )
          ],
          itemMarketMapping: mapping,
        ));
      }
    }

    // STRATEGY: SPLIT PURCHASE (Melhor Custo-Benefício / Lowest Cost)
    double splitTotalCost = 0;
    int splitMissing = 0;
    final splitMapping = <String, String>{};
    final marketCosts = <String, double>{};
    final marketItemCounts = <String, int>{};

    for (final listItem in items) {
      final itemPrices = priceMap[listItem.itemId];
      if (itemPrices == null || itemPrices.isEmpty) {
        splitMissing++;
        continue;
      }

      // Find cheapest market for this item
      String? bestMarketId;
      double lowestPrice = double.infinity;

      for (final entry in itemPrices.entries) {
        final mId = entry.key;
        final p = entry.value;
        
        // Só considera se a unidade bater
        if (p.unit == listItem.unit) {
          final cost = p.calculateBestPrice(listItem.plannedQuantity);
          if (cost < lowestPrice) {
            lowestPrice = cost;
            bestMarketId = mId;
          }
        }
      }

      if (bestMarketId != null) {
        splitTotalCost += lowestPrice;
        splitMapping[listItem.id] = bestMarketId;
        marketCosts[bestMarketId] = (marketCosts[bestMarketId] ?? 0) + lowestPrice;
        marketItemCounts[bestMarketId] = (marketItemCounts[bestMarketId] ?? 0) + 1;
      } else {
        splitMissing++;
      }
    }

    if (marketItemCounts.length > 1) {
      final summaries = marketItemCounts.entries.map((e) {
        final mId = e.key;
        return StrategyMarketSummary(
          marketId: mId,
          marketName: marketMap[mId]?.name ?? 'Desconhecido',
          cost: marketCosts[mId] ?? 0,
          itemsCount: e.value,
        );
      }).toList();

      // Sort summaries by cost descending
      summaries.sort((a, b) => b.cost.compareTo(a.cost));

      strategies.add(PurchaseStrategy(
        id: 'split_optimal',
        title: 'Dividir Compras',
        description: 'Melhor economia aproveitando o preço mais baixo de cada mercado.',
        totalCost: splitTotalCost,
        missingItemsCount: splitMissing,
        marketSummaries: summaries,
        itemMarketMapping: splitMapping,
      ));
    }

    // Sort all strategies: first by missing items (ascending), then by cost (ascending)
    strategies.sort((a, b) {
      if (a.missingItemsCount != b.missingItemsCount) {
        return a.missingItemsCount.compareTo(b.missingItemsCount);
      }
      return a.totalCost.compareTo(b.totalCost);
    });

    return strategies;
  }
}
