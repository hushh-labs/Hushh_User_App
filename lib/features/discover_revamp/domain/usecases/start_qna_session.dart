import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/qna_session.dart';
import '../repositories/qna_repository.dart';

class StartQnASession implements UseCase<QnASession, StartQnASessionParams> {
  final QnARepository repository;

  StartQnASession(this.repository);

  @override
  Future<Either<Failure, QnASession>> call(StartQnASessionParams params) async {
    return await repository.startQnASession(params.agentId, params.agentName);
  }
}

class StartQnASessionParams {
  final String agentId;
  final String agentName;

  StartQnASessionParams({required this.agentId, required this.agentName});
}
