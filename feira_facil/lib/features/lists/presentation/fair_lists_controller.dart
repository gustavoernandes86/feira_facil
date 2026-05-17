import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fair_list.dart';
import '../domain/list_item.dart';
import 'package:feira_facil/core/utils/unit_utils.dart';
import '../data/fair_lists_repository.dart';
import '../../groups/data/group_repository.dart';
import '../../../core/providers/user_providers.dart';
import '../../notifications/data/notification_repository.dart';

/// Stream de listas manuais de um grupo
final fairListsStreamProvider = StreamProvider.family<List<FairList>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(fairListsRepositoryProvider);
  return repository.listsStream(groupId).map(
    (lists) => lists.where((l) => !l.isSuggested).toList(),
  );
});

/// Stream de listas sugeridas de um grupo (geradas via comparação)
final suggestedListsStreamProvider =
    StreamProvider.family<List<FairList>, String>((ref, groupId) {
      final repository = ref.watch(fairListsRepositoryProvider);
      return repository.listsStream(groupId).map(
        (lists) => lists.where((l) => l.isSuggested).toList(),
      );
    });

/// Obtém todos os itens de uma lista
final listItemsStreamProvider =
    StreamProvider.family<List<ListItem>, ({String groupId, String listId})>((
      ref,
      params,
    ) {
      final repository = ref.watch(fairListsRepositoryProvider);
      return repository.listItemsStream(params.groupId, params.listId);
    });

/// Representa uma feira ativa (compra sugerida em andamento)
class ActiveFeira {
  final FairList list;
  final List<ListItem> items;

  ActiveFeira({required this.list, required this.items});
}

/// Provedor para obter a feira ativa em andamento (compra sugerida)
final activeFeiraProvider = Provider.family<ActiveFeira?, String>((ref, groupId) {
  final suggestedListsAsync = ref.watch(suggestedListsStreamProvider(groupId));
  final suggestedLists = suggestedListsAsync.value ?? [];

  debugPrint('[DEBUG] activeFeiraProvider: groupId=$groupId, suggestedLists.length=${suggestedLists.length}');
  for (final l in suggestedLists) {
    debugPrint('[DEBUG]   list: ${l.id}, name: ${l.name}, status: ${l.status}, isSuggested: ${l.isSuggested}');
  }

  FairList? activeList;
  for (final l in suggestedLists) {
    if (l.status != 'concluida') {
      activeList = l;
      break;
    }
  }

  if (activeList == null) {
    debugPrint('[DEBUG] activeFeiraProvider: activeList is null');
    return null;
  }

  final itemsAsync = ref.watch(
    listItemsStreamProvider((groupId: groupId, listId: activeList.id)),
  );
  final items = itemsAsync.value ?? [];
  debugPrint('[DEBUG] activeFeiraProvider: activeList=${activeList.name}, items.length=${items.length}');
  for (final item in items) {
    if (item.marked) {
      debugPrint('[DEBUG]   item marked: ${item.itemId}');
    }
  }

  final hasMarked = items.any((item) => item.marked);
  if (hasMarked || activeList.status == 'em_compra') {
    debugPrint('[DEBUG] activeFeiraProvider: RETURNING ActiveFeira for ${activeList.name}');
    return ActiveFeira(list: activeList, items: items);
  }

  debugPrint('[DEBUG] activeFeiraProvider: hasMarked=$hasMarked, status=${activeList.status} -> returning null');
  return null;
});

/// Controller para gerenciar listas de compras
final fairListsControllerProvider =
    AsyncNotifierProvider.family<FairListsController, void, String>(
      FairListsController.new,
    );

class FairListsController extends FamilyAsyncNotifier<void, String> {
  late final String groupId;

  @override
  FutureOr<void> build(String arg) {
    groupId = arg;
  }

  /// Cria uma nova lista de compras
  Future<void> createList({
    required String name,
    required Color color,
    double? budget,
    required String userId,
    bool copyFromBaseList = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      final newListId = await repository.createList(
        groupId: groupId,
        name: name,
        color: color,
        budget: budget,
        userId: userId,
      );

      if (copyFromBaseList) {
        await repository.copyBaseListItems(
          groupId: groupId,
          targetListId: newListId,
        );
      }

      // Enviar Notificação
      try {
        final groupRepo = ref.read(groupRepositoryProvider);
        final group = await groupRepo.getGroup(groupId);
        final userProfile = ref.read(currentUserProfileProvider).value;
        if (group != null && userProfile != null) {
          await ref.read(notificationRepositoryProvider).sendNotificationToUsers(
            targetUserIds: group.memberIds,
            title: 'Nova Lista de Compras',
            body: '${userProfile.name ?? 'Um membro'} criou a lista "$name"',
            type: 'list_created',
            relatedGroupId: groupId,
            relatedListId: newListId,
            senderId: userId,
            senderName: userProfile.name,
          );
        }
      } catch (_) {}

      ref.invalidate(fairListsStreamProvider(groupId));
    });
  }

  /// Verifica e cria a lista padrão se necessário
  Future<void> checkDefaultList(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.seedDefaultListIfNeeded(groupId, userId);
      // Invalida para garantir que a UI pegue a nova lista se ela foi criada
      ref.invalidate(fairListsStreamProvider(groupId));
    });
  }

  /// Adiciona um item à lista
  Future<void> addItemToList({
    required String listId,
    required String itemId,
    double quantity = 1.0,
    ItemUnit unit = ItemUnit.un,
    String category = 'Outros',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.addItemToList(
        groupId: groupId,
        listId: listId,
        itemId: itemId,
        quantity: quantity,
        unit: unit,
        category: category,
      );

      ref.invalidate(
        listItemsStreamProvider((groupId: groupId, listId: listId)),
      );
    });
  }

  /// Atualiza a quantidade de um item na lista
  Future<void> updateItemQuantity({
    required String listId,
    required String listItemId,
    required double newQuantity,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.updateListItemQuantity(
        groupId: groupId,
        listId: listId,
        listItemId: listItemId,
        quantity: newQuantity,
      );

      ref.invalidate(
        listItemsStreamProvider((groupId: groupId, listId: listId)),
      );
    });
  }

  /// Marca um item como "Peguei!"
  Future<void> toggleItemMarked({
    required String listId,
    required String listItemId,
    required bool marked,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.toggleItemMarked(
        groupId: groupId,
        listId: listId,
        listItemId: listItemId,
        marked: marked,
      );

      ref.invalidate(
        listItemsStreamProvider((groupId: groupId, listId: listId)),
      );
    });
  }

  /// Remove um item da lista
  Future<void> removeItemFromList({
    required String listId,
    required String listItemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.removeItemFromList(
        groupId: groupId,
        listId: listId,
        listItemId: listItemId,
      );

      ref.invalidate(
        listItemsStreamProvider((groupId: groupId, listId: listId)),
      );
    });
  }

  /// Atualiza o orçamento da lista
  Future<void> updateListBudget({
    required String listId,
    required double budget,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.updateListBudget(
        groupId: groupId,
        listId: listId,
        budget: budget,
      );

      ref.invalidate(fairListsStreamProvider(groupId));
    });
  }

  /// Inicia o modo compra (seleciona um mercado)
  Future<void> startShoppingMode({
    required String listId,
    required String marketId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.updateListMarket(
        groupId: groupId,
        listId: listId,
        marketId: marketId,
      );

      ref.invalidate(fairListsStreamProvider(groupId));
    });
  }

  /// Conclui a lista
  Future<void> completeList(String listId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.updateListStatus(
        groupId: groupId,
        listId: listId,
        status: 'concluida',
      );

      ref.invalidate(fairListsStreamProvider(groupId));
      ref.invalidate(suggestedListsStreamProvider(groupId));
    });
  }

  /// Atualiza a quantidade no carrinho durante modo compra
  Future<void> updateCartQuantity({
    required String listId,
    required String listItemId,
    double? cartQuantity,
    bool? marked,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);

      if (cartQuantity != null) {
        await repository.updateCartQuantity(
          groupId: groupId,
          listId: listId,
          listItemId: listItemId,
          cartQuantity: cartQuantity,
        );
      }

      if (marked != null) {
        await repository.toggleItemMarked(
          groupId: groupId,
          listId: listId,
          listItemId: listItemId,
          marked: marked,
        );
      }

      ref.invalidate(
        listItemsStreamProvider((groupId: groupId, listId: listId)),
      );
    });
  }

  /// Deleta uma lista
  Future<void> deleteList(String listId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      await repository.deleteList(groupId: groupId, listId: listId);

      ref.invalidate(fairListsStreamProvider(groupId));
      ref.invalidate(suggestedListsStreamProvider(groupId));
    });
  }

  /// Limpa o histórico de compras finalizadas
  Future<void> clearFinishedLists(List<FairList> lists) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fairListsRepositoryProvider);
      for (final list in lists) {
        await repository.deleteList(groupId: groupId, listId: list.id);
      }

      ref.invalidate(fairListsStreamProvider(groupId));
      ref.invalidate(suggestedListsStreamProvider(groupId));
    });
  }
}
