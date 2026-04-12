import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromJson({'id': doc.id, ...doc.data()!});
  }

  Future<void> ensureUserExists({
    required String userId,
    required String email,
    String? name,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      if (name != null) 'name': name,
      // We don't initialize groupIds here to avoid overwriting existing data
    }, SetOptions(merge: true));
  }
  
  Stream<AppUser?> watchUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  Future<List<AppUser>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    // Firestore filters limit to 30 items for 'whereIn'. 
    // For now, our groups are small, so this is fine.
    final snapshot = await _firestore.collection('users')
      .where(FieldPath.documentId, whereIn: userIds)
      .get();
      
    return snapshot.docs.map((doc) => AppUser.fromJson({'id': doc.id, ...doc.data()})).toList();
  }
}
