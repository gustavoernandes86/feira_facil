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

  CollectionReference<Map<String, dynamic>> get _groups => _firestore.collection('grupos');

  Future<FamilyGroup> createGroup(String name, String userId) async {
    final inviteCode = _generateInviteCode();
    
    final docRef = _groups.doc();
    final newGroup = FamilyGroup(
      id: docRef.id,
      name: name,
      inviteCode: inviteCode,
      memberIds: [userId],
    );

    await docRef.set(newGroup.toJson());
    
    // Atualizar o usuário para incluir o novo grupo e marcar como o último acessado
    await _firestore.collection('users').doc(userId).set({
      'groupIds': FieldValue.arrayUnion([docRef.id]),
      'lastGroupId': docRef.id,
    }, SetOptions(merge: true));

    return newGroup;
  }

  Future<FamilyGroup?> joinGroup(String inviteCode, String userId) async {
    final snapshot = await _groups.where('inviteCode', isEqualTo: inviteCode).limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      throw Exception('Código de convite inválido.');
    }

    final groupDoc = snapshot.docs.first;
    final group = FamilyGroup.fromJson({'id': groupDoc.id, ...groupDoc.data()});

    if (!group.memberIds.contains(userId)) {
      await groupDoc.reference.update({
        'memberIds': FieldValue.arrayUnion([userId])
      });
      
      await _firestore.collection('users').doc(userId).set({
        'groupIds': FieldValue.arrayUnion([groupDoc.id]),
        'lastGroupId': groupDoc.id,
      }, SetOptions(merge: true));
    }

    return group;
  }

  Stream<FamilyGroup?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FamilyGroup.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  Future<void> switchActiveGroup(String userId, String groupId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastGroupId': groupId,
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
