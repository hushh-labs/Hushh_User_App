import 'package:dartz/dartz.dart';
import '../entities/cart_notification_entity.dart';
import '../repositories/cart_notification_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

class SendCartNotificationUseCase
    implements UseCase<bool, CartNotificationEntity> {
  final CartNotificationRepository repository;

  SendCartNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CartNotificationEntity params) async {
    return await repository.sendCartNotification(params);
  }
}
