import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/feira_item.dart';

// Modelo para um ponto histórico de preço
class HistoricalPrice {
  final double price;
  final String marketName;
  final DateTime date;

  HistoricalPrice({required this.price, required this.marketName, required this.date});
}

// Provedor que busca o histórico de preços de um item no grupo
final priceHistoryProvider = FutureProvider.family<List<HistoricalPrice>, ({String groupId, String itemName, String currentItemId})>((ref, arg) async {
  if (arg.itemName.isEmpty) return [];

  final firestore = FirebaseFirestore.instance;
  
  final snapshot = await firestore
      .collectionGroup('items')
      .where('groupId', isEqualTo: arg.groupId)
      .where('name', isEqualTo: arg.itemName)
      .orderBy('date', descending: true)
      .limit(20) // Pegamos mais pontos para o gráfico
      .get();

  if (snapshot.docs.isEmpty) return [];

  return snapshot.docs
      .map((doc) => FeiraItem.fromJson(doc.data()))
      .where((item) => item.id != arg.currentItemId)
      .map((item) => HistoricalPrice(
            price: item.unitPrice,
            marketName: item.marketName ?? 'Mercado Desconhecido',
            date: item.date ?? DateTime.now(),
          ))
      .toList();
});

// Modelo simples para o resultado da comparação
class PriceTrend {
  final double difference;
  final bool isCheaper;
  final bool isVarying;

  PriceTrend({required this.difference, required this.isCheaper, required this.isVarying});
}

final priceTrendProvider = Provider.family<PriceTrend?, ({String groupId, String itemName, String currentItemId, double currentPrice})>((ref, arg) {
  final historyAsync = ref.watch(priceHistoryProvider((
    groupId: arg.groupId, 
    itemName: arg.itemName, 
    currentItemId: arg.currentItemId
  )));

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty || arg.currentPrice == 0) return null;
      
      final lastPrice = history.first.price;
      final diff = arg.currentPrice - lastPrice;
      if (diff.abs() < 0.01) return null; 

      return PriceTrend(
        difference: diff.abs(),
        isCheaper: diff < 0,
        isVarying: true,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provedor que avisa se o preço atual está MUITO acima do melhor preço histórico recente
final bestPriceAlertProvider = Provider.family<HistoricalPrice?, ({String groupId, String itemName, String currentItemId, double currentPrice})>((ref, arg) {
  final historyAsync = ref.watch(priceHistoryProvider((
    groupId: arg.groupId, 
    itemName: arg.itemName, 
    currentItemId: arg.currentItemId
  )));

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) return null;

      // Encontrar o melhor preço nos últimos 30 dias
      final bestDeal = history.fold<HistoricalPrice?>(null, (best, current) {
        if (best == null || current.price < best.price) return current;
        return best;
      });

      // Se o preço atual for > 15% mais caro que o melhor deal, exibir alerta
      if (bestDeal != null && arg.currentPrice > bestDeal.price * 1.15) {
        return bestDeal;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
