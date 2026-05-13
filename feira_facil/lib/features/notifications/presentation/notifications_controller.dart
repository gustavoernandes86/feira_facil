import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.read(notificationRepositoryProvider).watchUserNotifications(user.id);
});

final unreadNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.read(notificationRepositoryProvider).watchUnreadNotifications(user.id);
});

final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  final Ref _ref;

  NotificationController(this._ref);

  Future<void> markAsRead(String notificationId) async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user != null) {
      await _ref.read(notificationRepositoryProvider).markAsRead(user.id, notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user != null) {
      await _ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    }
  }
}
