import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/market.dart';

final marketsRepositoryProvider = Provider<MarketsRepository>((ref) {
  return MarketsRepository(FirebaseFirestore.instance);
});

class MarketsRepository {
  final FirebaseFirestore _firestore;

  MarketsRepository(this._firestore);

  /// Cria um novo mercado
  Future<String> createMarket({
    required String groupId,
    required String name,
    required String address,
    required String userId,
    String? observations,
  }) async {
    try {
      final marketRef = _firestore
          .collection('grupos')
          .doc(groupId)
          .collection('mercados')
          .doc();

      await marketRef.set({
        'name': name,
        'address': address,
        'observations': observations ?? '',
        'rating': 0.0,
        'createdBy': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return marketRef.id;
    } catch (e) {
      throw Exception('Erro ao criar mercado: $e');
    }
  }

  /// Obtém todos os mercados de um grupo
  Future<List<Market>> getMarkets(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('grupos')
          .doc(groupId)
          .collection('mercados')
          .get();

      return snapshot.docs
          .map((doc) => Market.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar mercados: $e');
    }
  }

  /// Stream de mercados de um grupo (tempo real)
  Stream<List<Market>> marketsStream(String groupId) {
    return _firestore
        .collection('grupos')
        .doc(groupId)
        .collection('mercados')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Market.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'groupId': groupId,
                }),
              )
              .toList(),
        );
  }

  /// Atualiza um mercado
  Future<void> updateMarket(
    String groupId,
    String marketId,
    Market market,
  ) async {
    try {
      await _firestore
          .collection('grupos')
          .doc(groupId)
          .collection('mercados')
          .doc(marketId)
          .update(
            market.toJson()
              ..remove('id')
              ..remove('groupId'),
          );
    } catch (e) {
      throw Exception('Erro ao atualizar mercado: $e');
    }
  }

  /// Deleta um mercado
  Future<void> deleteMarket(String groupId, String marketId) async {
    try {
      await _firestore
          .collection('grupos')
          .doc(groupId)
          .collection('mercados')
          .doc(marketId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar mercado: $e');
    }
  }

  /// Obtém um mercado específico
  Future<Market?> getMarket(String groupId, String marketId) async {
    try {
      final doc = await _firestore
          .collection('grupos')
          .doc(groupId)
          .collection('mercados')
          .doc(marketId)
          .get();

      if (!doc.exists) return null;
      return Market.fromJson({
        ...doc.data()!,
        'id': doc.id,
        'groupId': groupId,
      });
    } catch (e) {
      throw Exception('Erro ao buscar mercado: $e');
    }
  }
}
