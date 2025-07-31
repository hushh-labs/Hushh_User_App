import 'package:dartz/dartz.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/notification_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteNotifications = await remoteDataSource.getNotifications();
        return remoteNotifications.fold((failure) => Left(failure), (
          notifications,
        ) async {
          // Cache the notifications locally
          for (final notification in notifications) {
            await localDataSource.saveNotification(notification);
          }
          return Right(notifications.map((n) => n.toEntity()).toList());
        });
      } catch (e) {
        return Left(
          ServerFailure('Failed to get notifications from server: $e'),
        );
      }
    } else {
      // Return cached notifications when offline
      final localNotifications = await localDataSource.getNotifications();
      return localNotifications.fold(
        (failure) => Left(failure),
        (notifications) =>
            Right(notifications.map((n) => n.toEntity()).toList()),
      );
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> getNotificationById(
    String id,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteNotification = await remoteDataSource.getNotificationById(
          id,
        );
        return remoteNotification.fold((failure) => Left(failure), (
          notification,
        ) async {
          await localDataSource.saveNotification(notification);
          return Right(notification.toEntity());
        });
      } catch (e) {
        return Left(
          ServerFailure('Failed to get notification from server: $e'),
        );
      }
    } else {
      final localNotification = await localDataSource.getNotificationById(id);
      return localNotification.fold(
        (failure) => Left(failure),
        (notification) => Right(notification.toEntity()),
      );
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> createNotification(
    NotificationEntity notification,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final notificationModel = NotificationModel.fromEntity(notification);
        final remoteResult = await remoteDataSource.createNotification(
          notificationModel,
        );
        return remoteResult.fold((failure) => Left(failure), (
          createdNotification,
        ) async {
          await localDataSource.saveNotification(createdNotification);
          return Right(createdNotification.toEntity());
        });
      } catch (e) {
        return Left(ServerFailure('Failed to create notification: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> updateNotification(
    NotificationEntity notification,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final notificationModel = NotificationModel.fromEntity(notification);
        final remoteResult = await remoteDataSource.updateNotification(
          notificationModel,
        );
        return remoteResult.fold((failure) => Left(failure), (
          updatedNotification,
        ) async {
          await localDataSource.updateNotification(updatedNotification);
          return Right(updatedNotification.toEntity());
        });
      } catch (e) {
        return Left(ServerFailure('Failed to update notification: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.markAsRead(id);
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.markAsRead(id);
          }
          return Right(success);
        });
      } catch (e) {
        return Left(ServerFailure('Failed to mark notification as read: $e'));
      }
    } else {
      return await localDataSource.markAsRead(id);
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.markAllAsRead();
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.markAllAsRead();
          }
          return Right(success);
        });
      } catch (e) {
        return Left(
          ServerFailure('Failed to mark all notifications as read: $e'),
        );
      }
    } else {
      return await localDataSource.markAllAsRead();
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotification(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.deleteNotification(id);
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.deleteNotification(id);
          }
          return Right(success);
        });
      } catch (e) {
        return Left(ServerFailure('Failed to delete notification: $e'));
      }
    } else {
      return await localDataSource.deleteNotification(id);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAllNotifications() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.deleteAllNotifications();
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.deleteAllNotifications();
          }
          return Right(success);
        });
      } catch (e) {
        return Left(ServerFailure('Failed to delete all notifications: $e'));
      }
    } else {
      return await localDataSource.deleteAllNotifications();
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.getUnreadCount();
        return remoteResult.fold(
          (failure) => Left(failure),
          (count) => Right(count),
        );
      } catch (e) {
        return Left(ServerFailure('Failed to get unread count: $e'));
      }
    } else {
      return await localDataSource.getUnreadCount();
    }
  }

  @override
  Future<Either<Failure, bool>> updateNotificationSettings(
    Map<String, bool> settings,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.updateNotificationSettings(
          settings,
        );
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.saveNotificationSettings(settings);
          }
          return Right(success);
        });
      } catch (e) {
        return Left(
          ServerFailure('Failed to update notification settings: $e'),
        );
      }
    } else {
      return await localDataSource.saveNotificationSettings(settings);
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.getNotificationSettings();
        return remoteResult.fold((failure) => Left(failure), (settings) async {
          await localDataSource.saveNotificationSettings(settings);
          return Right(settings);
        });
      } catch (e) {
        return Left(ServerFailure('Failed to get notification settings: $e'));
      }
    } else {
      return await localDataSource.getNotificationSettings();
    }
  }

  @override
  Future<Either<Failure, String?>> getFCMToken() async {
    return await localDataSource.getFCMToken();
  }

  @override
  Future<Either<Failure, bool>> updateFCMToken(String token) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.updateFCMToken(token);
        return remoteResult.fold((failure) => Left(failure), (success) async {
          if (success) {
            await localDataSource.saveFCMToken(token);
          }
          return Right(success);
        });
      } catch (e) {
        return Left(ServerFailure('Failed to update FCM token: $e'));
      }
    } else {
      return await localDataSource.saveFCMToken(token);
    }
  }

  @override
  Future<Either<Failure, bool>> initializeNotifications() async {
    try {
      // Initialize local storage
      await localDataSource.getNotifications();

      // Get FCM token if connected
      if (await networkInfo.isConnected) {
        final fcmToken = await getFCMToken();
        fcmToken.fold((failure) => null, (token) async {
          if (token != null) {
            await updateFCMToken(token);
          }
        });
      }

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to initialize notifications: $e'));
    }
  }
}
