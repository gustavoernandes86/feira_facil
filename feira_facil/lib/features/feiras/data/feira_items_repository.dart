import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/feira_item.dart';

final feiraItemsRepositoryProvider = Provider<FeiraItemsRepository>((ref) {
  return FeiraItemsRepository(FirebaseFirestore.instance);
});

final feiraItemsStreamProvider = StreamProvider.family<List<FeiraItem>, String>((ref, feiraId) {
  final repository = ref.watch(feiraItemsRepositoryProvider);
  return repository.watchItems(feiraId);
});

class FeiraItemsRepository {
  final FirebaseFirestore _firestore;

  FeiraItemsRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _itemsRef(String feiraId) {
    return _firestore.collection('feiras').doc(feiraId).collection('items');
  }

  Stream<List<FeiraItem>> watchItems(String feiraId) {
    return _itemsRef(feiraId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeiraItem.fromJson(doc.data())).toList();
    });
  }

  Future<List<FeiraItem>> getItemsOnce(String feiraId) async {
    final snapshot = await _itemsRef(feiraId).get();
    return snapshot.docs.map((doc) => FeiraItem.fromJson(doc.data())).toList();
  }

  Future<void> addItem(String feiraId, FeiraItem item) async {
    await _itemsRef(feiraId).doc(item.id).set(item.toJson());
  }

  Future<void> updateItem(String feiraId, FeiraItem item) async {
    await _itemsRef(feiraId).doc(item.id).update(item.toJson());
  }

  Future<void> deleteItem(String feiraId, String itemId) async {
    await _itemsRef(feiraId).doc(itemId).delete();
  }
}
