import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetNotificationsUseCase
    implements UseCase<List<NotificationEntity>, NoParams> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getNotifications();
  }
}
