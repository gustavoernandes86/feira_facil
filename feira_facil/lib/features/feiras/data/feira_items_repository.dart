import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/feira_item.dart';

final feiraItemsRepositoryProvider = Provider<FeiraItemsRepository>((ref) {
  return FeiraItemsRepository(FirebaseFirestore.instance);
});

/// Stream de itens de uma feira específica (tempo real)
final feiraItemsStreamProvider = StreamProvider.family<List<FeiraItem>, String>(
  (ref, feiraId) {
    final repository = ref.watch(feiraItemsRepositoryProvider);
    return repository.itemsStream(feiraId);
  },
);

class FeiraItemsRepository {
  final FirebaseFirestore _firestore;

  FeiraItemsRepository(this._firestore);

  /// Referência para os itens de uma feira específica
  CollectionReference<Map<String, dynamic>> _itemsRef(String feiraId) {
    return _firestore.collection('feiras').doc(feiraId).collection('itens');
  }

  /// Stream de todos os itens de uma feira (tempo real)
  Stream<List<FeiraItem>> itemsStream(String feiraId) {
    return _itemsRef(feiraId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => FeiraItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  /// Stream de itens por categoria em uma feira
  Stream<List<FeiraItem>> itemsByCategoryStream(
    String feiraId,
    String category,
  ) {
    return _itemsRef(feiraId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeiraItem.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Obtém itens de uma vez (snapshot atual)
  Future<List<FeiraItem>> getItemsOnce(String feiraId) async {
    final snapshot = await _itemsRef(feiraId).get();
    return snapshot.docs
        .map((doc) => FeiraItem.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Cria um novo item e atualiza a contagem da feira
  Future<String> addItem(String feiraId, FeiraItem item) async {
    try {
      final docRef = _itemsRef(feiraId).doc();
      await docRef.set({
        'name': item.name,
        'brand': item.brand,
        'category': item.category,
        'unit': item.unit,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'isAdded': item.isAdded,
        if (item.groupId != null) 'groupId': item.groupId,
        if (item.marketName != null) 'marketName': item.marketName,
      });
      await _updateFeiraItemsCount(feiraId);
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar item: $e');
    }
  }

  /// Atualiza um item
  Future<void> updateItem(String feiraId, FeiraItem item) async {
    try {
      await _itemsRef(feiraId).doc(item.id).update({
        'name': item.name,
        'brand': item.brand,
        'category': item.category,
        'unit': item.unit,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'isAdded': item.isAdded,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar item: $e');
    }
  }

  /// Marca/desmarca item como adicionado e atualiza contagem de checked
  Future<void> toggleItem(String feiraId, String itemId, bool isAdded) async {
    try {
      await _itemsRef(feiraId).doc(itemId).update({'isAdded': isAdded});
      await _updateFeiraItemsCount(feiraId);
    } catch (e) {
      throw Exception('Erro ao atualizar item: $e');
    }
  }

  /// Deleta um item e atualiza a contagem da feira
  Future<void> deleteItem(String feiraId, String itemId) async {
    try {
      await _itemsRef(feiraId).doc(itemId).delete();
      await _updateFeiraItemsCount(feiraId);
    } catch (e) {
      throw Exception('Erro ao deletar item: $e');
    }
  }

  /// Obtém um item específico
  Future<FeiraItem?> getItem(String feiraId, String itemId) async {
    try {
      final doc = await _itemsRef(feiraId).doc(itemId).get();
      if (!doc.exists) return null;
      return FeiraItem.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Erro ao buscar item: $e');
    }
  }

  /// Busca items por nome (partial match)
  Future<List<FeiraItem>> searchItems(String feiraId, String query) async {
    try {
      final snapshot = await _itemsRef(feiraId).get();
      final items = snapshot.docs
          .map((doc) => FeiraItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      final lowerQuery = query.toLowerCase();
      return items
          .where(
            (item) =>
                item.name.toLowerCase().contains(lowerQuery) ||
                item.brand.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar itens: $e');
    }
  }

  /// Atualiza o itemsCount e checkedItemsCount no documento da Feira
  Future<void> _updateFeiraItemsCount(String feiraId) async {
    try {
      final items = await getItemsOnce(feiraId);
      final totalCount = items.length;
      final checkedCount = items.where((i) => i.isAdded).length;
      final totalSpent = items
          .where((i) => i.isAdded)
          .fold(0.0, (acc, i) => acc + (i.unitPrice * i.quantity));
      final estimatedTotal = items.fold(
          0.0, (acc, i) => acc + (i.unitPrice * i.quantity));

      await _firestore.collection('feiras').doc(feiraId).update({
        'itemsCount': totalCount,
        'checkedItemsCount': checkedCount,
        'totalSpent': totalSpent,
        'estimatedTotal': estimatedTotal,
      });
    } catch (e) {
      // Silently ignore if feira doc doesn't exist yet
    }
  }
}
