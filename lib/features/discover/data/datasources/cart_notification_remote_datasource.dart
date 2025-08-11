import 'package:dartz/dartz.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/constants/firestore_constants.dart';
import '../models/cart_notification_model.dart';

abstract class CartNotificationRemoteDataSource {
  Future<Either<Failure, bool>> sendCartNotification(
    CartNotificationModel notification,
  );
}

class CartNotificationRemoteDataSourceImpl
    implements CartNotificationRemoteDataSource {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, bool>> sendCartNotification(
    CartNotificationModel notification,
  ) async {
    try {
      final user = _auth.currentUser;
      logger.log('Current user: ${user?.uid}', level: LogLevel.debug, tag: 'CartNotif');
      logger.log('User display name: ${user?.displayName}', level: LogLevel.debug, tag: 'CartNotif');
      logger.log('User email: ${user?.email}', level: LogLevel.debug, tag: 'CartNotif');

      if (user == null) {
        logger.log('User not authenticated - returning error', level: LogLevel.error, tag: 'CartNotif');
        return Left(ServerFailure('User not authenticated'));
      }

      // Fetch user's full name from Firestore
      String userName = 'User'; // Default fallback
      try {
        final userDoc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['fullName'] ??
              userData?['name'] ??
              user.displayName ??
              'User';
          logger.log('User full name from Firestore: $userName', level: LogLevel.debug, tag: 'CartNotif');
        } else {
          logger.log('User document not found in Firestore, using fallback name', level: LogLevel.warning, tag: 'CartNotif');
        }
      } catch (e) {
        logger.log('Error fetching user name from Firestore: $e', level: LogLevel.warning, tag: 'CartNotif');
        userName = user.displayName ?? 'User';
      }

      // Add user info to notification
      final notificationData = {
        ...notification.toJson(),
        'userId': user.uid,
        'userName': userName,
      };

      logger.log('Calling cloud function with data: $notificationData', level: LogLevel.debug, tag: 'CartNotif');

      // Call cloud function
      final result = await _functions
          .httpsCallable('sendCartItemNotification')
          .call(notificationData);

      logger.log('Cart notification sent successfully: ${result.data}', level: LogLevel.info, tag: 'CartNotif');
      return const Right(true);
    } catch (error) {
      logger.log('Error sending cart notification: $error', level: LogLevel.error, tag: 'CartNotif');
      logger.log('Error type: ${error.runtimeType}', level: LogLevel.error, tag: 'CartNotif');
      logger.log('Error details: ${error.toString()}', level: LogLevel.error, tag: 'CartNotif');
      return Left(ServerFailure('Failed to send cart notification: $error'));
    }
  }
}
