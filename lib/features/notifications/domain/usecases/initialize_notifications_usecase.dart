import 'package:dartz/dartz.dart';
import '../repositories/notification_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

class InitializeNotificationsUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  InitializeNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.initializeNotifications();
  }
}
