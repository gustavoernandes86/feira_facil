import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fair_list.dart';
import '../domain/list_item.dart';

final fairListsRepositoryProvider = Provider<FairListsRepository>((ref) {
  return FairListsRepository(FirebaseFirestore.instance);
});

class FairListsRepository {
  final FirebaseFirestore _firestore;

  FairListsRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _listsRef(String groupId) {
    return _firestore.collection('grupos').doc(groupId).collection('listas');
  }

  CollectionReference<Map<String, dynamic>> _listItemsRef(
    String groupId,
    String listId,
  ) {
    return _listsRef(groupId).doc(listId).collection('itens');
  }

  /// Cria uma nova lista de compras
  Future<String> createList({
    required String groupId,
    required String name,
    required Color color,
    double? budget,
    required String userId,
  }) async {
    try {
      final docRef = _listsRef(groupId).doc();

      await docRef.set({
        'name': name,
        'color': color.value,
        'status': 'ativa',
        'budget': budget,
        'activeMarketId': null,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': userId,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar lista: $e');
    }
  }

  /// Stream de listas de um grupo (tempo real)
  Stream<List<FairList>> listsStream(String groupId) {
    return _listsRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FairList.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Verifica se há listas e, se não houver, cria a lista padrão
  Future<void> seedDefaultListIfNeeded(String groupId, String userId) async {
    try {
      final snapshot = await _listsRef(groupId).limit(1).get();
      if (snapshot.docs.isEmpty) {
        // Nenhuma lista existe, vamos criar a Lista Básica
        final listId = await createList(
          groupId: groupId,
          name: 'Lista Básica',
          color: const Color(0xFF4CAF50), // Verde
          userId: userId,
        );

        // Itens da Lista Básica
        final defaultItems = [
          // Hortifruti
          {'id': 'Banana prata', 'qty': 2},
          {'id': 'Maçã', 'qty': 2},
          {'id': 'Mamão', 'qty': 2},
          {'id': 'Manga', 'qty': 4},
          {'id': 'Laranja', 'qty': 2},
          {'id': 'Limão', 'qty': 1},
          {'id': 'Tomate', 'qty': 2},
          {'id': 'Cebola', 'qty': 1},
          {'id': 'Alho', 'qty': 1},
          {'id': 'Batata', 'qty': 2},
          {'id': 'Cenoura', 'qty': 1},
          {'id': 'Abóbora', 'qty': 1},
          {'id': 'Pimentão', 'qty': 3},
          {'id': 'Coentro', 'qty': 2},
          {'id': 'Cebolinha', 'qty': 2},
          {'id': 'Alface', 'qty': 3},
          {'id': 'Repolho', 'qty': 1},
          // Carnes e Ovos
          {'id': 'Peito de frango', 'qty': 3},
          {'id': 'Carne bovina', 'qty': 2},
          {'id': 'Carne moída', 'qty': 1},
          {'id': 'Linguiça', 'qty': 1},
          {'id': 'Ovos', 'qty': 3},
          // Peixes
          {'id': 'Filé de peixe', 'qty': 2},
          // Laticínios
          {'id': 'Leite', 'qty': 30},
          {'id': 'Queijo coalho', 'qty': 1},
          {'id': 'Queijo muçarela', 'qty': 1},
          {'id': 'Iogurte', 'qty': 12},
          // Padaria
          {'id': 'Pão francês', 'qty': 30},
          {'id': 'Pão de forma', 'qty': 2},
          {'id': 'Bolo simples', 'qty': 2},
          // Grãos e Cereais
          {'id': 'Arroz', 'qty': 5},
          {'id': 'Feijão', 'qty': 2},
          {'id': 'Macarrão', 'qty': 1},
          {'id': 'Flocão de milho', 'qty': 1},
          {'id': 'Farinha de mandioca', 'qty': 1},
          {'id': 'Aveia', 'qty': 1},
          // Mercearia
          {'id': 'Óleo de soja', 'qty': 2},
          {'id': 'Azeite', 'qty': 1},
          {'id': 'Açúcar', 'qty': 2},
          {'id': 'Café', 'qty': 1},
          {'id': 'Sal', 'qty': 1},
          {'id': 'Molho de tomate', 'qty': 3},
          {'id': 'Milho verde', 'qty': 2},
          {'id': 'Sardinha/atum', 'qty': 4},
          // Bebidas
          {'id': 'Água mineral', 'qty': 6},
          {'id': 'Refrigerante', 'qty': 4},
          {'id': 'Suco', 'qty': 6},
          // Limpeza
          {'id': 'Detergente', 'qty': 3},
          {'id': 'Sabão em pó', 'qty': 1},
          {'id': 'Água sanitária', 'qty': 2},
          {'id': 'Desinfetante', 'qty': 2},
          {'id': 'Esponja', 'qty': 2},
          {'id': 'Saco de lixo', 'qty': 2},
          // Higiene
          {'id': 'Papel higiênico', 'qty': 24},
          {'id': 'Creme dental', 'qty': 3},
          {'id': 'Sabonete', 'qty': 6},
          {'id': 'Shampoo', 'qty': 2},
          {'id': 'Condicionador', 'qty': 1},
          {'id': 'Desodorante', 'qty': 2},
        ];

        for (final item in defaultItems) {
          await addItemToList(
            groupId: groupId,
            listId: listId,
            itemId: item['id'] as String,
            quantity: item['qty'] as int,
          );
        }
      }
    } catch (e) {
      throw Exception('Erro ao popular lista padrão: $e');
    }
  }

  /// Adiciona um item à lista
  Future<String> addItemToList({
    required String groupId,
    required String listId,
    required String itemId,
    int quantity = 1,
  }) async {
    try {
      final docRef = _listItemsRef(groupId, listId).doc();

      await docRef.set({
        'itemId': itemId,
        'plannedQuantity': quantity,
        'cartQuantity': 0,
        'marked': false,
        'selectedMarketId': null,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar item à lista: $e');
    }
  }

  /// Stream de itens de uma lista (tempo real)
  Stream<List<ListItem>> listItemsStream(String groupId, String listId) {
    return _listItemsRef(groupId, listId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ListItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  /// Atualiza a quantidade planejada de um item
  Future<void> updateListItemQuantity({
    required String groupId,
    required String listId,
    required String listItemId,
    required int quantity,
  }) async {
    try {
      await _listItemsRef(
        groupId,
        listId,
      ).doc(listItemId).update({'plannedQuantity': quantity});
    } catch (e) {
      throw Exception('Erro ao atualizar quantidade: $e');
    }
  }

  /// Marca/desmarca um item como "Peguei!"
  Future<void> toggleItemMarked({
    required String groupId,
    required String listId,
    required String listItemId,
    required bool marked,
  }) async {
    try {
      await _listItemsRef(
        groupId,
        listId,
      ).doc(listItemId).update({'marked': marked});
    } catch (e) {
      throw Exception('Erro ao marcar item: $e');
    }
  }

  /// Remove um item da lista
  Future<void> removeItemFromList({
    required String groupId,
    required String listId,
    required String listItemId,
  }) async {
    try {
      await _listItemsRef(groupId, listId).doc(listItemId).delete();
    } catch (e) {
      throw Exception('Erro ao remover item: $e');
    }
  }

  /// Atualiza o orçamento da lista
  Future<void> updateListBudget({
    required String groupId,
    required String listId,
    required double budget,
  }) async {
    try {
      await _listsRef(groupId).doc(listId).update({'budget': budget});
    } catch (e) {
      throw Exception('Erro ao atualizar orçamento: $e');
    }
  }

  /// Seleciona um mercado para o modo compra
  Future<void> updateListMarket({
    required String groupId,
    required String listId,
    required String marketId,
  }) async {
    try {
      await _listsRef(
        groupId,
      ).doc(listId).update({'activeMarketId': marketId, 'status': 'em_compra'});
    } catch (e) {
      throw Exception('Erro ao iniciar modo compra: $e');
    }
  }

  /// Atualiza o status da lista
  Future<void> updateListStatus({
    required String groupId,
    required String listId,
    required String status,
  }) async {
    try {
      await _listsRef(groupId).doc(listId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// Deleta uma lista
  Future<void> deleteList({
    required String groupId,
    required String listId,
  }) async {
    try {
      await _listsRef(groupId).doc(listId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar lista: $e');
    }
  }

  /// Obtém uma lista específica
  Future<FairList?> getList(String groupId, String listId) async {
    try {
      final doc = await _listsRef(groupId).doc(listId).get();
      if (!doc.exists) return null;
      return FairList.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Erro ao buscar lista: $e');
    }
  }

  /// Atualiza a quantidade no carrinho
  Future<void> updateCartQuantity({
    required String groupId,
    required String listId,
    required String listItemId,
    required int cartQuantity,
  }) async {
    try {
      await _listItemsRef(
        groupId,
        listId,
      ).doc(listItemId).update({'cartQuantity': cartQuantity});
    } catch (e) {
      throw Exception('Erro ao atualizar carrinho: $e');
    }
  }
}
