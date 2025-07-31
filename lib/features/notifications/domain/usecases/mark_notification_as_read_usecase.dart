import 'package:dartz/dartz.dart';
import '../repositories/notification_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

class MarkNotificationAsReadUseCase implements UseCase<bool, String> {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String notificationId) async {
    return await repository.markAsRead(notificationId);
  }
}
