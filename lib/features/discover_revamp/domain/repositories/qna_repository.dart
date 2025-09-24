import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/qna_session.dart';
import '../entities/answer.dart';

abstract class QnARepository {
  Future<Either<Failure, QnASession>> startQnASession(
    String agentId,
    String agentName,
  );
  Future<Either<Failure, QnASession>> submitAnswer(
    String sessionId,
    Answer answer,
  );
  Future<Either<Failure, QnASession>> completeQnASession(String sessionId);
  Future<Either<Failure, QnASession>> getQnASession(String sessionId);
}
