import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../../../../core/errors/failures.dart';

abstract class NotificationRemoteDataSource {
  Future<Either<Failure, List<NotificationModel>>> getNotifications();
  Future<Either<Failure, NotificationModel>> getNotificationById(String id);
  Future<Either<Failure, NotificationModel>> createNotification(
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
  Future<Either<Failure, bool>> updateNotificationSettings(
    Map<String, bool> settings,
  );
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings();
  Future<Either<Failure, String?>> getFCMToken();
  Future<Either<Failure, bool>> updateFCMToken(String token);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _hushUsersCollection = 'HushUsers';
  static const String _notificationsCollection = 'notifications';

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final querySnapshot = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .orderBy('created_at', descending: true)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure('Failed to get notifications: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> getNotificationById(
    String id,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final doc = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return Left(ServerFailure('Notification not found'));
      }

      return Right(NotificationModel.fromJson(doc.data()!));
    } catch (e) {
      return Left(ServerFailure('Failed to get notification: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> createNotification(
    NotificationModel notification,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toJson());

      return Right(notification);
    } catch (e) {
      return Left(ServerFailure('Failed to create notification: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> updateNotification(
    NotificationModel notification,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .doc(notification.id)
          .update(notification.toJson());

      return Right(notification);
    } catch (e) {
      return Left(ServerFailure('Failed to update notification: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .doc(id)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          });

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to mark notification as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      return const Right(true);
    } catch (e) {
      return Left(
        ServerFailure('Failed to mark all notifications as read: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotification(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .doc(id)
          .delete();

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to delete notification: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final querySnapshot = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to delete all notifications: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final querySnapshot = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .collection(_notificationsCollection)
          .where('is_read', isEqualTo: false)
          .get();

      return Right(querySnapshot.docs.length);
    } catch (e) {
      return Left(ServerFailure('Failed to get unread count: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateNotificationSettings(
    Map<String, bool> settings,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      await _firestore.collection(_hushUsersCollection).doc(user.uid).update({
        'notification_settings': settings,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to update notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final doc = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Return default settings if user document doesn't exist
        return const Right({
          'chat': true,
          'system': true,
          'marketing': false,
          'reminder': true,
          'update': true,
        });
      }

      final data = doc.data();
      final settings = data?['notification_settings'] as Map<String, dynamic>?;

      if (settings == null) {
        return const Right({
          'chat': true,
          'system': true,
          'marketing': false,
          'reminder': true,
          'update': true,
        });
      }

      return Right(Map<String, bool>.from(settings));
    } catch (e) {
      return Left(ServerFailure('Failed to get notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final doc = await _firestore
          .collection(_hushUsersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return const Right(null);
      }

      final data = doc.data();
      return Right(data?['fcm_token'] as String?);
    } catch (e) {
      return Left(ServerFailure('Failed to get FCM token: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      // Save FCM token to HushUsers collection under the current user's UID
      await _firestore.collection(_hushUsersCollection).doc(user.uid).set({
        'fcm_token': token,
        'platform': _getPlatform(),
        'last_token_update': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to update FCM token: $e'));
    }
  }

  String _getPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (kIsWeb) {
      return 'web';
    } else {
      return 'unknown';
    }
  }
}
