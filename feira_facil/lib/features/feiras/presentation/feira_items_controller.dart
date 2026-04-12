import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feira_items_repository.dart';
import '../data/feira_repository.dart';
import '../domain/feira_item.dart';

final feiraItemsControllerProvider =
    AsyncNotifierProvider.family<FeiraItemsController, void, String>(
  FeiraItemsController.new,
);

class FeiraItemsController extends AsyncNotifier<void> {
  final String _feiraId;
  FeiraItemsController(this._feiraId);

  @override
  FutureOr<void> build() {
    // No arg here anymore in 3.0
  }

  Future<void> addItem(FeiraItem item) async {
    final repo = ref.read(feiraItemsRepositoryProvider);
    await repo.addItem(_feiraId, item);
    await _refreshTotal();
  }

  Future<void> toggleItem(FeiraItem item, bool isAdded) async {
    final repo = ref.read(feiraItemsRepositoryProvider);
    await repo.updateItem(_feiraId, item.copyWith(isAdded: isAdded));
    await _refreshTotal();
  }

  Future<void> removeItem(String itemId) async {
    final repo = ref.read(feiraItemsRepositoryProvider);
    await repo.deleteItem(_feiraId, itemId);
    await _refreshTotal();
  }

  Future<void> updateBudget(double budget) async {
    await ref.read(feiraRepositoryProvider).updateBudget(_feiraId, budget);
  }

  Future<void> _refreshTotal() async {
    final repo = ref.read(feiraItemsRepositoryProvider);
    final snapshot = await repo.getItemsOnce(_feiraId);
    
    double totalSpent = 0;
    double estimatedTotal = 0;
    int itemsCount = snapshot.length;
    int checkedItemsCount = 0;

    for (var item in snapshot) {
      final itemValue = item.unitPrice * item.quantity;
      estimatedTotal += itemValue;
      if (item.isAdded) {
        totalSpent += itemValue;
        checkedItemsCount++;
      }
    }

    // Atualiza o documento pai com todos os metadados
    await ref.read(feiraRepositoryProvider).updateFeiraStats(
      feiraId: _feiraId,
      totalSpent: totalSpent,
      estimatedTotal: estimatedTotal,
      itemsCount: itemsCount,
      checkedItemsCount: checkedItemsCount,
    );
  }
}
