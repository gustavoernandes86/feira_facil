import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/feira.dart';
import '../../../core/providers/user_providers.dart';

final feiraRepositoryProvider = Provider<FeiraRepository>((ref) {
  return FeiraRepository(FirebaseFirestore.instance);
});

final groupFeirasProvider = StreamProvider<List<Feira>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return Stream.value([]);
  
  final repository = ref.watch(feiraRepositoryProvider);
  return repository.watchFeirasPorGrupo(groupId);
});

final feiraProvider = StreamProvider.family<Feira?, String>((ref, feiraId) {
  final repository = ref.watch(feiraRepositoryProvider);
  return repository.watchFeira(feiraId);
});

class FeiraRepository {
  final FirebaseFirestore _firestore;

  FeiraRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _feiras => _firestore.collection('feiras');

  Stream<Feira?> watchFeira(String feiraId) {
    return _feiras.doc(feiraId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Feira.fromJson(doc.data()!);
    });
  }

  Stream<List<Feira>> watchFeirasPorGrupo(String groupId) {
    return _feiras
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Feira.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<void> createFeira(Feira feira) async {
    await _feiras.doc(feira.id).set(feira.toJson());
  }

  Future<void> updateFeiraStats({
    required String feiraId,
    required double totalSpent,
    required double estimatedTotal,
    required int itemsCount,
    required int checkedItemsCount,
  }) async {
    await _feiras.doc(feiraId).update({
      'totalSpent': totalSpent,
      'estimatedTotal': estimatedTotal,
      'itemsCount': itemsCount,
      'checkedItemsCount': checkedItemsCount,
    });
  }

  Future<void> updateFeiraStatus(String feiraId, FeiraStatus status) async {
    await _feiras.doc(feiraId).update({
      'status': status.name,
    });
  }

  Future<void> updateBudget(String feiraId, double budget) async {
    await _feiras.doc(feiraId).update({
      'budget': budget,
    });
  }

  Future<void> deleteFeira(String feiraId) async {
    await _feiras.doc(feiraId).delete();
  }
}
