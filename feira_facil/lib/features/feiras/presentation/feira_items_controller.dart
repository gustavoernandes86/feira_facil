import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feira_items_repository.dart';
import '../data/feira_repository.dart';
import '../domain/feira_item.dart';

final feiraItemsControllerProvider =
    AsyncNotifierProvider.family<FeiraItemsController, void, String>(
      FeiraItemsController.new,
    );

class FeiraItemsController extends FamilyAsyncNotifier<void, String> {
  late final String _feiraId;

  @override
  FutureOr<void> build(String arg) {
    _feiraId = arg;
  }

  Future<void> addItem(FeiraItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feiraItemsRepositoryProvider);
      await repo.addItem(_feiraId, item);
      ref.invalidate(feiraItemsStreamProvider(_feiraId));
    });
  }

  Future<void> toggleItem(FeiraItem item, bool isAdded) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feiraItemsRepositoryProvider);
      await repo.toggleItem(_feiraId, item.id, isAdded);
      ref.invalidate(feiraItemsStreamProvider(_feiraId));
    });
  }

  Future<void> updateItem(FeiraItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feiraItemsRepositoryProvider);
      await repo.updateItem(_feiraId, item);
      ref.invalidate(feiraItemsStreamProvider(_feiraId));
    });
  }

  Future<void> removeItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feiraItemsRepositoryProvider);
      await repo.deleteItem(_feiraId, itemId);
      ref.invalidate(feiraItemsStreamProvider(_feiraId));
    });
  }

  Future<void> updateBudget(double budget) async {
    await ref.read(feiraRepositoryProvider).updateBudget(_feiraId, budget);
  }
}
