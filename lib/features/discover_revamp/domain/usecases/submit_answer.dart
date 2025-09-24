import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/qna_session.dart';
import '../entities/answer.dart';
import '../repositories/qna_repository.dart';

class SubmitAnswer implements UseCase<QnASession, SubmitAnswerParams> {
  final QnARepository repository;

  SubmitAnswer(this.repository);

  @override
  Future<Either<Failure, QnASession>> call(SubmitAnswerParams params) async {
    return await repository.submitAnswer(params.sessionId, params.answer);
  }
}

class SubmitAnswerParams {
  final String sessionId;
  final Answer answer;

  SubmitAnswerParams({required this.sessionId, required this.answer});
}
