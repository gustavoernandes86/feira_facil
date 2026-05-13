import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(FirebaseFirestore.instance);
});

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _userNotificationsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('notifications');
  }

  // Enviar uma notificação para vários usuários
  Future<void> sendNotificationToUsers({
    required List<String> targetUserIds,
    required String title,
    required String body,
    required String type,
    String? relatedGroupId,
    String? relatedListId,
    String? senderId,
    String? senderName,
  }) async {
    final batch = _firestore.batch();
    
    for (final userId in targetUserIds) {
      if (userId == senderId) continue; // Não notificar a si mesmo
      
      final ref = _userNotificationsRef(userId).doc();
      final notification = AppNotification(
        id: ref.id,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        relatedGroupId: relatedGroupId,
        relatedListId: relatedListId,
        senderId: senderId,
        senderName: senderName,
      );
      
      batch.set(ref, notification.toJson());
    }
    
    await batch.commit();
  }

  // Marcar uma notificação como lida
  Future<void> markAsRead(String userId, String notificationId) async {
    await _userNotificationsRef(userId).doc(notificationId).update({'isRead': true});
  }

  // Marcar todas como lidas
  Future<void> markAllAsRead(String userId) async {
    final unreadQuery = await _userNotificationsRef(userId).where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    
    for (final doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  // Stream de notificações de um usuário
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _userNotificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppNotification.fromJson(doc.data())).toList();
    });
  }

  // Stream apenas de notificações não lidas
  Stream<List<AppNotification>> watchUnreadNotifications(String userId) {
    return _userNotificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppNotification.fromJson(doc.data())).toList();
    });
  }
}
