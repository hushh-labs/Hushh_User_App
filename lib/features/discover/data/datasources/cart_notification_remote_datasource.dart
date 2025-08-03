import 'package:dartz/dartz.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Current user: ${user?.uid}');
      debugPrint('User display name: ${user?.displayName}');
      debugPrint('User email: ${user?.email}');

      if (user == null) {
        debugPrint('User not authenticated - returning error');
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
          debugPrint('User full name from Firestore: $userName');
        } else {
          debugPrint(
            'User document not found in Firestore, using fallback name',
          );
        }
      } catch (e) {
        debugPrint('Error fetching user name from Firestore: $e');
        userName = user.displayName ?? 'User';
      }

      // Add user info to notification
      final notificationData = {
        ...notification.toJson(),
        'userId': user.uid,
        'userName': userName,
      };

      debugPrint('Calling cloud function with data: $notificationData');

      // Call cloud function
      final result = await _functions
          .httpsCallable('sendCartItemNotification')
          .call(notificationData);

      debugPrint('Cart notification sent successfully: ${result.data}');
      return const Right(true);
    } catch (error) {
      debugPrint('Error sending cart notification: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Error details: ${error.toString()}');
      return Left(ServerFailure('Failed to send cart notification: $error'));
    }
  }
}
