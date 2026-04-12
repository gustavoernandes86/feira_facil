import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/market.dart';
import '../../../core/providers/user_providers.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(FirebaseFirestore.instance);
});

final groupMarketsProvider = StreamProvider<List<Market>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return Stream.value([]);
  
  final repository = ref.watch(marketRepositoryProvider);
  return repository.watchMarketsByGroup(groupId);
});

class MarketRepository {
  final FirebaseFirestore _firestore;

  MarketRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _markets => _firestore.collection('markets');

  Stream<List<Market>> watchMarketsByGroup(String groupId) {
    return _markets
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Market.fromJson(doc.data())).toList();
    });
  }

  Future<void> createMarket(Market market) async {
    await _markets.doc(market.id).set(market.toJson());
  }

  Future<void> deleteMarket(String marketId) async {
    await _markets.doc(marketId).delete();
  }
}
