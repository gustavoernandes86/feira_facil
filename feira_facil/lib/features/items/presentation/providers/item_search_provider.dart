import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feira_facil/core/providers/user_providers.dart';

/// Provedor que extrai nomes únicos de produtos a partir de todas as "feiras" do grupo.
/// Isso permite o preenchimento automático (autocomplete) ao cadastrar novos preços.
final groupItemNamesProvider = StreamProvider<List<String>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  return firestore
      .collectionGroup('itens') // Usando o path unificado que corrigimos
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((snapshot) {
    // Extrai nomes únicos e ordena alfabeticamente
    final names = snapshot.docs
        .map((doc) => doc.data()['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  });
});
