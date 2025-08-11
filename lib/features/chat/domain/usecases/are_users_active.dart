import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class AreUsersActive implements UseCase<bool, List<String>> {
  final ChatRepository repository;

  AreUsersActive(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<String> userIds) async {
    return await repository.areUsersActive(userIds);
  }
}
