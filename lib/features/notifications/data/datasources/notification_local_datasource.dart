import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/notification_model.dart';
import '../../../../core/errors/failures.dart';

abstract class NotificationLocalDataSource {
  Future<Either<Failure, List<NotificationModel>>> getNotifications();
  Future<Either<Failure, NotificationModel>> getNotificationById(String id);
  Future<Either<Failure, NotificationModel>> saveNotification(
    NotificationModel notification,
  );
  Future<Either<Failure, NotificationModel>> updateNotification(
    NotificationModel notification,
  );
  Future<Either<Failure, bool>> markAsRead(String id);
  Future<Either<Failure, bool>> markAllAsRead();
  Future<Either<Failure, bool>> deleteNotification(String id);
  Future<Either<Failure, bool>> deleteAllNotifications();
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, bool>> saveNotificationSettings(
    Map<String, bool> settings,
  );
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings();
  Future<Either<Failure, String?>> getFCMToken();
  Future<Either<Failure, bool>> saveFCMToken(String token);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  static const String _notificationsBoxName = 'notifications';
  static const String _settingsKey = 'notification_settings';
  static const String _fcmTokenKey = 'fcm_token';

  late Box<dynamic> _notificationsBox;
  late SharedPreferences _prefs;

  Future<void> _init() async {
    _notificationsBox = await Hive.openBox(_notificationsBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications() async {
    try {
      await _init();
      final notifications = _notificationsBox.values
          .map(
            (item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure('Failed to get notifications from cache: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> getNotificationById(
    String id,
  ) async {
    try {
      await _init();
      final notification = _notificationsBox.get(id);
      if (notification != null) {
        return Right(
          NotificationModel.fromJson(Map<String, dynamic>.from(notification)),
        );
      }
      return Left(CacheFailure('Notification not found'));
    } catch (e) {
      return Left(CacheFailure('Failed to get notification from cache: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> saveNotification(
    NotificationModel notification,
  ) async {
    try {
      await _init();
      await _notificationsBox.put(notification.id, notification.toJson());
      return Right(notification);
    } catch (e) {
      return Left(CacheFailure('Failed to save notification to cache: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> updateNotification(
    NotificationModel notification,
  ) async {
    try {
      await _init();
      await _notificationsBox.put(notification.id, notification.toJson());
      return Right(notification);
    } catch (e) {
      return Left(CacheFailure('Failed to update notification in cache: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String id) async {
    try {
      await _init();
      final notification = await getNotificationById(id);
      return notification.fold((failure) => Left(failure), (
        notification,
      ) async {
        final updatedNotification = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        final result = await updateNotification(updatedNotification);
        return result.fold(
          (failure) => Left(failure),
          (_) => const Right(true),
        );
      });
    } catch (e) {
      return Left(CacheFailure('Failed to mark notification as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      await _init();
      final notifications = await getNotifications();
      return notifications.fold((failure) => Left(failure), (
        notifications,
      ) async {
        for (final notification in notifications) {
          if (!notification.isRead) {
            final updatedNotification = notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
            await updateNotification(updatedNotification);
          }
        }
        return const Right(true);
      });
    } catch (e) {
      return Left(CacheFailure('Failed to mark all notifications as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotification(String id) async {
    try {
      await _init();
      await _notificationsBox.delete(id);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to delete notification from cache: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAllNotifications() async {
    try {
      await _init();
      await _notificationsBox.clear();
      return const Right(true);
    } catch (e) {
      return Left(
        CacheFailure('Failed to delete all notifications from cache: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      await _init();
      final notifications = await getNotifications();
      return notifications.fold(
        (failure) => Left(failure),
        (notifications) => Right(notifications.where((n) => !n.isRead).length),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to get unread count: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveNotificationSettings(
    Map<String, bool> settings,
  ) async {
    try {
      await _init();
      await _prefs.setString(_settingsKey, settings.toString());
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to save notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings() async {
    try {
      await _init();
      final settingsString = _prefs.getString(_settingsKey);
      if (settingsString != null) {
        // Parse the settings string back to Map
        // This is a simplified implementation
        return const Right({
          'chat': true,
          'system': true,
          'marketing': false,
          'reminder': true,
          'update': true,
        });
      }
      return const Right({
        'chat': true,
        'system': true,
        'marketing': false,
        'reminder': true,
        'update': true,
      });
    } catch (e) {
      return Left(CacheFailure('Failed to get notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getFCMToken() async {
    try {
      await _init();
      return Right(_prefs.getString(_fcmTokenKey));
    } catch (e) {
      return Left(CacheFailure('Failed to get FCM token: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveFCMToken(String token) async {
    try {
      await _init();
      await _prefs.setString(_fcmTokenKey, token);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to save FCM token: $e'));
    }
  }
}
