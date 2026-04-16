import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/family_group.dart';
import 'dart:math';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(FirebaseFirestore.instance);
});

class GroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('grupos');

  /// Cria um novo grupo familiar e atualiza o perfil do usuário
  Future<FamilyGroup> createGroup(String name, String userId) async {
    final inviteCode = _generateInviteCode();

    final docRef = _groups.doc();
    final newGroup = FamilyGroup(
      id: docRef.id,
      name: name,
      inviteCode: inviteCode,
      memberIds: [userId],
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await docRef.set(newGroup.toJson());

    // Atualizar o usuário para incluir o novo grupo e marcar como o último acessado
    await _firestore.collection('users').doc(userId).set({
      'groupIds': FieldValue.arrayUnion([docRef.id]),
      'lastGroupId': docRef.id,
    }, SetOptions(merge: true));

    return newGroup;
  }

  /// Entra em um grupo pelo código de convite
  Future<FamilyGroup?> joinGroup(String inviteCode, String userId) async {
    final snapshot = await _groups
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Código de convite inválido.');
    }

    final groupDoc = snapshot.docs.first;
    final group =
        FamilyGroup.fromJson({'id': groupDoc.id, ...groupDoc.data()});

    if (!group.memberIds.contains(userId)) {
      await groupDoc.reference.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      await _firestore.collection('users').doc(userId).set({
        'groupIds': FieldValue.arrayUnion([groupDoc.id]),
        'lastGroupId': groupDoc.id,
      }, SetOptions(merge: true));
    }

    return group;
  }

  /// Remove um membro de um grupo
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    // Também remove o grupo da lista do usuário
    await _firestore.collection('users').doc(userId).update({
      'groupIds': FieldValue.arrayRemove([groupId]),
    });
  }

  /// Obtém um grupo por ID (leitura única)
  Future<FamilyGroup?> getGroup(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FamilyGroup.fromJson({'id': doc.id, ...doc.data()!});
  }

  /// Obtém um grupo pelo código de convite (leitura única)
  Future<FamilyGroup?> getGroupByInviteCode(String inviteCode) async {
    final query = await _groups
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return FamilyGroup.fromJson({'id': doc.id, ...doc.data()});
  }

  /// Stream de um grupo específico (tempo real)
  Stream<FamilyGroup?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FamilyGroup.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  /// Stream de todos os grupos do usuário (tempo real)
  Stream<List<FamilyGroup>> userGroupsStream(String userId) {
    return _groups
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FamilyGroup.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  /// Troca o grupo ativo do usuário
  Future<void> switchActiveGroup(String userId, String groupId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastGroupId': groupId,
    });
  }

  /// Gera um código de convite alfanumérico de 6 dígitos
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
