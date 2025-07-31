import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class NotificationRepository {
  // Get notifications
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, NotificationEntity>> getNotificationById(String id);

  // Create and update notifications
  Future<Either<Failure, NotificationEntity>> createNotification(
    NotificationEntity notification,
  );
  Future<Either<Failure, NotificationEntity>> updateNotification(
    NotificationEntity notification,
  );

  // Mark notifications as read
  Future<Either<Failure, bool>> markAsRead(String id);
  Future<Either<Failure, bool>> markAllAsRead();

  // Delete notifications
  Future<Either<Failure, bool>> deleteNotification(String id);
  Future<Either<Failure, bool>> deleteAllNotifications();

  // Get unread count
  Future<Either<Failure, int>> getUnreadCount();

  // Notification settings
  Future<Either<Failure, bool>> updateNotificationSettings(
    Map<String, bool> settings,
  );
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings();

  // FCM token management
  Future<Either<Failure, String?>> getFCMToken();
  Future<Either<Failure, bool>> updateFCMToken(String token);

  // Initialize notifications
  Future<Either<Failure, bool>> initializeNotifications();
}
