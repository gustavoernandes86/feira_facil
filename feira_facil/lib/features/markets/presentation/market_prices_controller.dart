import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/features/items/data/prices_repository.dart';
import 'package:feira_facil/features/items/domain/price.dart';
import 'package:feira_facil/features/items/domain/price_tier.dart';
import 'package:feira_facil/core/utils/unit_utils.dart';

/// Provider para buscar a lista de preços de um mercado específico via Stream
final marketPricesStreamProvider = StreamProvider.family<List<Price>, String>((ref, marketId) {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return Stream.value([]);
  
  return ref.read(pricesRepositoryProvider).marketPricesStream(groupId, marketId);
});

/// Controller para gerenciar ações de preços em um mercado (criar, deletar)
final marketPricesControllerProvider =
    AsyncNotifierProvider.family<MarketPricesController, void, String>(
      MarketPricesController.new,
    );

class MarketPricesController extends FamilyAsyncNotifier<void, String> {
  late final String _marketId;

  @override
  FutureOr<void> build(String arg) {
    _marketId = arg;
  }

  Future<void> addPrice({
    required String itemName,
    required List<PriceTier> tiers,
    required ItemUnit unit,
    String? observation,
    String? brand,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final groupId = ref.read(currentGroupIdProvider);
      final userProfile = ref.read(currentUserProfileProvider).value;
      final userId = userProfile?.id ?? 'unknown';
      
      if (groupId == null) throw Exception('Grupo não selecionado');

      await ref.read(pricesRepositoryProvider).createPrice(
        groupId: groupId,
        itemId: itemName, 
        marketId: _marketId,
        tiers: tiers,
        unit: unit,
        userId: userId,
        observation: observation,
        brand: brand,
        sourceType: 'manual',
      );
      
      ref.invalidate(marketPricesStreamProvider(_marketId));
    });
  }

  Future<void> deletePrice(String priceId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final groupId = ref.read(currentGroupIdProvider);
      if (groupId == null) return;

      await ref.read(pricesRepositoryProvider).deletePrice(
        groupId: groupId,
        priceId: priceId,
      );
      ref.invalidate(marketPricesStreamProvider(_marketId));
    });
  }
}
