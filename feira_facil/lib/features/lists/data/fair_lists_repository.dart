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
          (snapshot) {
            print('[DEBUG] listsStream groupId=$groupId => ${snapshot.docs.length} listas');
            for (var doc in snapshot.docs) {
              print('[DEBUG]   lista: ${doc.id} => ${doc.data()['name']}');
            }
            return snapshot.docs
                .map((doc) => FairList.fromJson({...doc.data(), 'id': doc.id}))
                .toList();
          },
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
          {'id': 'Banana prata', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Maçã', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Mamão', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Manga', 'qty': 4, 'cat': 'Hortifruti'},
          {'id': 'Laranja', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Limão', 'qty': 1, 'cat': 'Hortifruti'},
          {'id': 'Tomate', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Cebola', 'qty': 1, 'cat': 'Hortifruti'},
          {'id': 'Alho', 'qty': 1, 'cat': 'Hortifruti'},
          {'id': 'Batata', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Cenoura', 'qty': 1, 'cat': 'Hortifruti'},
          {'id': 'Abóbora', 'qty': 1, 'cat': 'Hortifruti'},
          {'id': 'Pimentão', 'qty': 3, 'cat': 'Hortifruti'},
          {'id': 'Coentro', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Cebolinha', 'qty': 2, 'cat': 'Hortifruti'},
          {'id': 'Alface', 'qty': 3, 'cat': 'Hortifruti'},
          {'id': 'Repolho', 'qty': 1, 'cat': 'Hortifruti'},
          // Carnes e Ovos
          {'id': 'Peito de frango', 'qty': 3, 'cat': 'Carnes'},
          {'id': 'Carne bovina', 'qty': 2, 'cat': 'Carnes'},
          {'id': 'Carne moída', 'qty': 1, 'cat': 'Carnes'},
          {'id': 'Linguiça', 'qty': 1, 'cat': 'Carnes'},
          {'id': 'Ovos', 'qty': 3, 'cat': 'Laticínios'},
          // Peixes
          {'id': 'Filé de peixe', 'qty': 2, 'cat': 'Carnes'},
          // Laticínios
          {'id': 'Leite', 'qty': 30, 'cat': 'Laticínios'},
          {'id': 'Queijo coalho', 'qty': 1, 'cat': 'Laticínios'},
          {'id': 'Queijo muçarela', 'qty': 1, 'cat': 'Laticínios'},
          {'id': 'Iogurte', 'qty': 12, 'cat': 'Laticínios'},
          // Padaria
          {'id': 'Pão francês', 'qty': 30, 'cat': 'Padaria'},
          {'id': 'Pão de forma', 'qty': 2, 'cat': 'Padaria'},
          {'id': 'Bolo simples', 'qty': 2, 'cat': 'Padaria'},
          // Grãos e Cereais
          {'id': 'Arroz', 'qty': 5, 'cat': 'Grãos'},
          {'id': 'Feijão', 'qty': 2, 'cat': 'Grãos'},
          {'id': 'Macarrão', 'qty': 1, 'cat': 'Grãos'},
          {'id': 'Flocão de milho', 'qty': 1, 'cat': 'Grãos'},
          {'id': 'Farinha de mandioca', 'qty': 1, 'cat': 'Grãos'},
          {'id': 'Aveia', 'qty': 1, 'cat': 'Grãos'},
          // Mercearia
          {'id': 'Óleo de soja', 'qty': 2, 'cat': 'Outros'},
          {'id': 'Azeite', 'qty': 1, 'cat': 'Outros'},
          {'id': 'Açúcar', 'qty': 2, 'cat': 'Outros'},
          {'id': 'Café', 'qty': 1, 'cat': 'Bebidas'},
          {'id': 'Sal', 'qty': 1, 'cat': 'Outros'},
          {'id': 'Molho de tomate', 'qty': 3, 'cat': 'Outros'},
          {'id': 'Milho verde', 'qty': 2, 'cat': 'Outros'},
          {'id': 'Sardinha/atum', 'qty': 4, 'cat': 'Outros'},
          // Bebidas
          {'id': 'Água mineral', 'qty': 6, 'cat': 'Bebidas'},
          {'id': 'Refrigerante', 'qty': 4, 'cat': 'Bebidas'},
          {'id': 'Suco', 'qty': 6, 'cat': 'Bebidas'},
          // Limpeza
          {'id': 'Detergente', 'qty': 3, 'cat': 'Limpeza'},
          {'id': 'Sabão em pó', 'qty': 1, 'cat': 'Limpeza'},
          {'id': 'Água sanitária', 'qty': 2, 'cat': 'Limpeza'},
          {'id': 'Desinfetante', 'qty': 2, 'cat': 'Limpeza'},
          {'id': 'Esponja', 'qty': 2, 'cat': 'Limpeza'},
          {'id': 'Saco de lixo', 'qty': 2, 'cat': 'Limpeza'},
          // Higiene
          {'id': 'Papel higiênico', 'qty': 24, 'cat': 'Higiene'},
          {'id': 'Creme dental', 'qty': 3, 'cat': 'Higiene'},
          {'id': 'Sabonete', 'qty': 6, 'cat': 'Higiene'},
          {'id': 'Shampoo', 'qty': 2, 'cat': 'Higiene'},
          {'id': 'Condicionador', 'qty': 1, 'cat': 'Higiene'},
          {'id': 'Desodorante', 'qty': 2, 'cat': 'Higiene'},
        ];

        for (final item in defaultItems) {
          await addItemToList(
            groupId: groupId,
            listId: listId,
            itemId: item['id'] as String,
            quantity: item['qty'] as int,
            category: item['cat'] as String,
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
    String category = 'Outros',
  }) async {
    try {
      final docRef = _listItemsRef(groupId, listId).doc();

      await docRef.set({
        'itemId': itemId,
        'plannedQuantity': quantity,
        'cartQuantity': 0,
        'marked': false,
        'selectedMarketId': null,
        'category': category,
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

  /// Copia os itens da "Lista Básica" para uma nova lista
  Future<void> copyBaseListItems({
    required String groupId,
    required String targetListId,
  }) async {
    try {
      // 1. Encontrar a Lista Básica (por nome)
      final snapshot = await _listsRef(groupId)
          .where('name', isEqualTo: 'Lista Básica')
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) return; // Não achou a lista básica
      
      final baseListId = snapshot.docs.first.id;
      
      // 2. Buscar itens da lista básica
      final itemsSnapshot = await _listItemsRef(groupId, baseListId).get();
      
      // 3. Adicionar itens na nova lista
      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        final newDocRef = _listItemsRef(groupId, targetListId).doc();
        batch.set(newDocRef, {
          'itemId': data['itemId'],
          'plannedQuantity': data['plannedQuantity'],
          'cartQuantity': 0,
          'marked': false,
          'selectedMarketId': null,
          'category': data['category'] ?? 'Outros',
        });
      }
      
      await batch.commit();
      
    } catch (e) {
      throw Exception('Erro ao copiar itens da lista base: $e');
    }
  }
}
