import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/qna_session.dart';
import '../repositories/qna_repository.dart';

class CompleteQnASession implements UseCase<QnASession, String> {
  final QnARepository repository;

  CompleteQnASession(this.repository);

  @override
  Future<Either<Failure, QnASession>> call(String sessionId) async {
    return await repository.completeQnASession(sessionId);
  }
}
