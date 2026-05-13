import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    required String body,
    required String type, // 'list_created', 'list_updated', etc.
    required bool isRead,
    required DateTime createdAt,
    String? relatedGroupId,
    String? relatedListId,
    String? senderId,
    String? senderName,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
