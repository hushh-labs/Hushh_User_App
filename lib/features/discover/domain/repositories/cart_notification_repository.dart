import 'package:dartz/dartz.dart';
import '../entities/cart_notification_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class CartNotificationRepository {
  Future<Either<Failure, bool>> sendCartNotification(
    CartNotificationEntity notification,
  );
}
