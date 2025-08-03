import 'package:dartz/dartz.dart';
import '../../domain/entities/cart_notification_entity.dart';
import '../../domain/repositories/cart_notification_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/cart_notification_remote_datasource.dart';
import '../models/cart_notification_model.dart';

class CartNotificationRepositoryImpl implements CartNotificationRepository {
  final CartNotificationRemoteDataSource remoteDataSource;

  CartNotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> sendCartNotification(
    CartNotificationEntity notification,
  ) async {
    try {
      // Convert entity to model
      final notificationModel = CartNotificationModel(
        productId: notification.productId,
        productName: notification.productName,
        productPrice: notification.productPrice,
        productImage: notification.productImage,
        agentId: notification.agentId,
        agentName: notification.agentName,
        userId: notification.userId,
        userName: notification.userName,
        quantity: notification.quantity,
      );

      return await remoteDataSource.sendCartNotification(notificationModel);
    } catch (error) {
      return Left(ServerFailure('Failed to send cart notification: $error'));
    }
  }
}
