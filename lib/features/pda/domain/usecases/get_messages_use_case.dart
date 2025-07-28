import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

class GetMessagesUseCase {
  final PdaRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<PdaMessage>>> call(String userId) async {
    return await repository.getMessages(userId);
  }
}
