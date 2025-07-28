import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

class ClearMessagesUseCase {
  final PdaRepository repository;

  ClearMessagesUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.clearMessages(userId);
  }
}
