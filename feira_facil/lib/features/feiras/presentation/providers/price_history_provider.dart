import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/feira_item.dart';

// Provedor que busca o histórico de preço de um item específico no grupo
final priceHistoryProvider = FutureProvider.family<double?, ({String groupId, String itemName, String currentItemId})>((ref, arg) async {
  if (arg.itemName.isEmpty) return null;

  final firestore = FirebaseFirestore.instance;
  
  // Busca no histórico de todos os itens do grupo com o mesmo nome
  // Ordenado pela data decrescente para pegar o mais recente
  final snapshot = await firestore
      .collectionGroup('items')
      .where('groupId', isEqualTo: arg.groupId)
      .where('name', isEqualTo: arg.itemName)
      .orderBy('date', descending: true)
      .limit(5) // Pegamos alguns para garantir que não pegamos o próprio item atual
      .get();

  if (snapshot.docs.isEmpty) return null;

  // Filtra o item atual (para não comparar o preço dele com ele mesmo)
  final previousItems = snapshot.docs
      .map((doc) => FeiraItem.fromJson(doc.data()))
      .where((item) => item.id != arg.currentItemId)
      .toList();

  if (previousItems.isEmpty) return null;

  // Retorna o preço do item mais recente encontrado
  return previousItems.first.unitPrice;
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
    data: (lastPrice) {
      if (lastPrice == null || lastPrice == 0 || arg.currentPrice == 0) return null;
      
      final diff = arg.currentPrice - lastPrice;
      if (diff.abs() < 0.01) return null; // Diferença insignificante

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
