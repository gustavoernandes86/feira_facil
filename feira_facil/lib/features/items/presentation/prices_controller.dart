import 'dart:async';
import 'package:feira_facil/core/utils/unit_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/price.dart';
import '../domain/price_tier.dart';
import '../data/prices_repository.dart';

/// Stream de preços de um item (últimos 30 dias)
final itemPricesStreamProvider =
    StreamProvider.family<List<Price>, ({String groupId, String itemId})>((
      ref,
      params,
    ) {
      final repository = ref.watch(pricesRepositoryProvider);
      return repository.recentPricesStream(params.groupId, params.itemId);
    });

/// Obtém os menores preços por mercado para um item
final lowestPricesProvider =
    FutureProvider.family<
      Map<String, Price>,
      ({String groupId, String itemId})
    >((ref, params) {
      final repository = ref.watch(pricesRepositoryProvider);
      return repository.getLowestPricesPerMarket(
        groupId: params.groupId,
        itemId: params.itemId,
      );
    });

/// Controller para gerenciar preços e modo compra
/// Note: To use with a specific groupId, instantiate PricesController(groupId) directly
/// or use this provider for general price management operations
final pricesControllerProvider = AsyncNotifierProvider<PricesController, void>(
  () => PricesController(''),
);

class PricesController extends AsyncNotifier<void> {
  late String groupId;

  PricesController(String gId) {
    groupId = gId;
  }

  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Cria um novo registro de preço com faixas progressivas
  Future<void> createPrice({
    required String itemId,
    required String marketId,
    required List<PriceTier> tiers,
    required ItemUnit unit,
    required String userId,
    String? observation,
    String? photoUrl,
    String sourceType = 'manual',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(pricesRepositoryProvider);
      await repository.createPrice(
        groupId: groupId,
        itemId: itemId,
        marketId: marketId,
        tiers: tiers,
        unit: unit,
        userId: userId,
        observation: observation,
        photoUrl: photoUrl,
        sourceType: sourceType,
      );

      // Invalida caches
      ref.invalidate(
        itemPricesStreamProvider((groupId: groupId, itemId: itemId)),
      );
      ref.invalidate(lowestPricesProvider((groupId: groupId, itemId: itemId)));
    });
  }

  /// Atualiza um registro de preço
  Future<void> updatePrice({
    required String priceId,
    required String itemId,
    required List<PriceTier> tiers,
    String? observation,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(pricesRepositoryProvider);
      await repository.updatePrice(
        groupId: groupId,
        priceId: priceId,
        tiers: tiers,
        observation: observation,
      );

      // Invalida caches
      ref.invalidate(
        itemPricesStreamProvider((groupId: groupId, itemId: itemId)),
      );
      ref.invalidate(lowestPricesProvider((groupId: groupId, itemId: itemId)));
    });
  }

  /// Deleta um registro de preço
  Future<void> deletePrice({
    required String priceId,
    required String itemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(pricesRepositoryProvider);
      await repository.deletePrice(groupId: groupId, priceId: priceId);

      // Invalida caches
      ref.invalidate(
        itemPricesStreamProvider((groupId: groupId, itemId: itemId)),
      );
      ref.invalidate(lowestPricesProvider((groupId: groupId, itemId: itemId)));
    });
  }

  /// Calcula o preço total para uma quantidade com aplicação automática de melhor faixa
  static double calculateBestPrice({
    required List<PriceTier> tiers,
    required double quantity,
  }) {
    if (tiers.isEmpty) return 0.0;

    // Encontra a melhor faixa aplicável (a com maior quantidadeMinima que ainda aplica)
    PriceTier? bestTier;
    for (final tier in tiers) {
      if (tier.quantityMinimum <= quantity) {
        if (bestTier == null ||
            tier.quantityMinimum > bestTier.quantityMinimum) {
          bestTier = tier;
        }
      }
    }

    return bestTier?.calculateTotal(quantity) ??
        tiers.first.calculateTotal(quantity);
  }

  /// Encontra a próxima faixa disponível para sugerir economia
  static PriceTier? getNextTierSuggestion({
    required List<PriceTier> tiers,
    required double currentQuantity,
  }) {
    if (tiers.isEmpty) return null;

    PriceTier? nextTier;
    for (final tier in tiers) {
      if (tier.quantityMinimum > currentQuantity) {
        if (nextTier == null ||
            tier.quantityMinimum < nextTier.quantityMinimum) {
          nextTier = tier;
        }
      }
    }
    return nextTier;
  }

  /// Calcula a economia ao atingir a próxima faixa
  static double calculatePotentialSavings({
    required List<PriceTier> tiers,
    required double currentQuantity,
  }) {
    final currentTierPrice = calculateBestPrice(
      tiers: tiers,
      quantity: currentQuantity,
    );
    final nextTier = getNextTierSuggestion(
      tiers: tiers,
      currentQuantity: currentQuantity,
    );

    if (nextTier == null) return 0.0;

    final nextTierPrice = nextTier.calculateTotal(currentQuantity + 1);
    return currentTierPrice - nextTierPrice;
  }
}
