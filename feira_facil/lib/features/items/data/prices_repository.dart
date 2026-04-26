import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feira_facil/core/utils/unit_utils.dart';
import '../domain/price.dart';
import '../domain/price_tier.dart';

final pricesRepositoryProvider = Provider<PricesRepository>((ref) {
  return PricesRepository(FirebaseFirestore.instance);
});

class PricesRepository {
  final FirebaseFirestore _firestore;

  PricesRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _pricesRef(String groupId) {
    return _firestore.collection('grupos').doc(groupId).collection('precos');
  }

  /// Cria um novo registro de preço com faixas progressivas
  Future<String> createPrice({
    required String groupId,
    required String itemId,
    required String marketId,
    required List<PriceTier> tiers,
    required ItemUnit unit,
    required String userId,
    String? observation,
    String? photoUrl,
    String? brand,
    String sourceType = 'manual',
  }) async {
    try {
      final docRef = _pricesRef(groupId).doc();

      await docRef.set({
        'itemId': itemId,
        'marketId': marketId,
        'tiers': tiers.map((tier) => tier.toJson()).toList(),
        'unit': unit.name,
        'observation': observation,
        'photoUrl': photoUrl,
        'brand': brand,
        'sourceType': sourceType,
        'registeredAt': DateTime.now().toIso8601String(),
        'registeredBy': userId,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar preço: $e');
    }
  }

  /// Obtém todos os preços de um item em um mercado specific
  Future<List<Price>> getPricesByItemAndMarket({
    required String groupId,
    required String itemId,
    required String marketId,
  }) async {
    try {
      final snapshot = await _pricesRef(groupId)
          .where('itemId', isEqualTo: itemId)
          .where('marketId', isEqualTo: marketId)
          .get();

      return snapshot.docs
          .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar preços: $e');
    }
  }

  /// Obtém todos os preços de um item em todos os mercados
  Future<List<Price>> getPricesByItem({
    required String groupId,
    required String itemId,
  }) async {
    try {
      final snapshot = await _pricesRef(groupId)
          .where('itemId', isEqualTo: itemId)
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar preços do item: $e');
    }
  }

  /// Stream de preços recentes de um item (últimos 30 dias)
  Stream<List<Price>> recentPricesStream(String groupId, String itemId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return _pricesRef(groupId)
        .where('itemId', isEqualTo: itemId)
        .where(
          'registeredAt',
          isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String(),
        )
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Obtém todos os preços de um mercado
  Future<List<Price>> getPricesByMarket({
    required String groupId,
    required String marketId,
  }) async {
    try {
      final snapshot = await _pricesRef(groupId)
          .where('marketId', isEqualTo: marketId)
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar preços do mercado: $e');
    }
  }

  /// Stream de preços de um mercado (tempo real)
  Stream<List<Price>> marketPricesStream(String groupId, String marketId) {
    return _pricesRef(groupId)
        .where('marketId', isEqualTo: marketId)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Atualiza um registro de preço
  Future<void> updatePrice({
    required String groupId,
    required String priceId,
    required List<PriceTier> tiers,
    String? observation,
  }) async {
    try {
      await _pricesRef(groupId).doc(priceId).update({
        'tiers': tiers.map((tier) => tier.toJson()).toList(),
        if (observation != null) 'observation': observation,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar preço: $e');
    }
  }

  /// Deleta um registro de preço
  Future<void> deletePrice({
    required String groupId,
    required String priceId,
  }) async {
    try {
      await _pricesRef(groupId).doc(priceId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar preço: $e');
    }
  }

  /// Obtém o melhor preço para um item em um mercado específico (mais recente)
  Future<Price?> getBestPriceForItemInMarket({
    required String groupId,
    required String itemId,
    required String marketId,
  }) async {
    try {
      final snapshot = await _pricesRef(groupId)
          .where('itemId', isEqualTo: itemId)
          .where('marketId', isEqualTo: marketId)
          .orderBy('registeredAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Price.fromJson({
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id,
      });
    } catch (e) {
      throw Exception('Erro ao buscar melhor preço: $e');
    }
  }

  /// Obtém os preços mais baratos de um item em todos os mercados
  Future<Map<String, Price>> getLowestPricesPerMarket({
    required String groupId,
    required String itemId,
  }) async {
    try {
      final prices = await getPricesByItem(groupId: groupId, itemId: itemId);

      final mapByMarket = <String, Price>{};
      for (final price in prices) {
        if (!mapByMarket.containsKey(price.marketId) ||
            price.tiers.isNotEmpty &&
                mapByMarket[price.marketId]!.tiers.isNotEmpty &&
                price.tiers.first.pricePerUnit <
                    mapByMarket[price.marketId]!.tiers.first.pricePerUnit) {
          mapByMarket[price.marketId] = price;
        }
      }

      return mapByMarket;
    } catch (e) {
      throw Exception('Erro ao buscar menores preços: $e');
    }
  }

  /// Obtém TODOS os preços de todos os itens do grupo (usado no motor de comparação)
  Future<List<Price>> getAllPrices(String groupId) async {
    try {
      final snapshot = await _pricesRef(groupId).get();
      return snapshot.docs
          .map((doc) => Price.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar todos os preços do grupo: $e');
    }
  }
}
