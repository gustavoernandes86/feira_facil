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

  Future<void> createFeira(Feira feira, {String? baseListId}) async {
    await _feiras.doc(feira.id).set(feira.toJson());
    
    // Copy items from base list if provided
    if (baseListId != null) {
      try {
        final listItemsSnapshot = await _firestore
            .collection('grupos')
            .doc(feira.groupId)
            .collection('listas')
            .doc(baseListId)
            .collection('itens')
            .get();
            
        if (listItemsSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          final feiraItensRef = _feiras.doc(feira.id).collection('itens'); // Note: 'itens' in portuguese per context
          
          for (var doc in listItemsSnapshot.docs) {
            final data = doc.data();
            final newItemRef = feiraItensRef.doc();
            batch.set(newItemRef, {
              'name': data['itemId'], // Base list itemId is the actual name
              'quantity': (data['plannedQuantity'] as num?)?.toDouble() ?? 1.0,
              'category': 'Geral', // Default or fetch if available
              'isAdded': false,
              'unit': 'un',
              'unitPrice': 0.0,
            });
          }
          
          await batch.commit();
          
          // Update item count on Feira
          await updateFeiraStats(
            feiraId: feira.id,
            totalSpent: 0,
            estimatedTotal: 0,
            itemsCount: listItemsSnapshot.docs.length,
            checkedItemsCount: 0,
          );
        }
      } catch (e) {
        print('Erro ao copiar itens da lista base: $e');
      }
    }
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
