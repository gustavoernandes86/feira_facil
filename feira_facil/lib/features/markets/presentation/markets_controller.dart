import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/market.dart';
import '../data/markets_repository.dart';

/// Stream de mercados de um grupo específico
final marketsStreamProvider = StreamProvider.family<List<Market>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(marketsRepositoryProvider);
  return repository.marketsStream(groupId);
});

/// Obtém todos os mercados de um grupo (uma vez)
final marketsProvider = FutureProvider.family<List<Market>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(marketsRepositoryProvider);
  return repository.getMarkets(groupId);
});

/// Controller para gerenciar mercados
final marketsControllerProvider =
    AsyncNotifierProvider<MarketsController, void>(
      () => MarketsController(''),
    );

class MarketsController extends AsyncNotifier<void> {
  final String groupId;

  MarketsController(this.groupId);

  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Cria um novo mercado
  Future<void> createMarket({
    required String name,
    required String address,
    String? observations,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(marketsRepositoryProvider);
      await repository.createMarket(
        groupId: groupId,
        name: name,
        address: address,
        userId: userId,
        observations: observations,
      );

      // Invalida o cache de mercados
      ref.invalidate(marketsProvider(groupId));
      ref.invalidate(marketsStreamProvider(groupId));
    });
  }

  /// Atualiza um mercado
  Future<void> updateMarket({
    required String marketId,
    required Market market,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(marketsRepositoryProvider);
      await repository.updateMarket(groupId, marketId, market);

      // Invalida o cache de mercados
      ref.invalidate(marketsProvider(groupId));
      ref.invalidate(marketsStreamProvider(groupId));
    });
  }

  /// Deleta um mercado
  Future<void> deleteMarket(String marketId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(marketsRepositoryProvider);
      await repository.deleteMarket(groupId, marketId);

      // Invalida o cache de mercados
      ref.invalidate(marketsProvider(groupId));
      ref.invalidate(marketsStreamProvider(groupId));
    });
  }
}
