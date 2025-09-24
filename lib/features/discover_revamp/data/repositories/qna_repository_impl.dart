import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/qna_session.dart';
import '../../domain/entities/answer.dart';
import '../../domain/repositories/qna_repository.dart';
import '../datasources/qna_remote_data_source.dart';
import '../models/qna_session_model.dart';
import '../models/answer_model.dart';

class QnARepositoryImpl implements QnARepository {
  final QnARemoteDataSource remoteDataSource;

  QnARepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, QnASession>> startQnASession(
    String agentId,
    String agentName,
  ) async {
    try {
      final session = await remoteDataSource.startQnASession(
        agentId,
        agentName,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QnASession>> submitAnswer(
    String sessionId,
    Answer answer,
  ) async {
    try {
      final answerModel = AnswerModel.fromEntity(answer);
      final session = await remoteDataSource.submitAnswer(
        sessionId,
        answerModel,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QnASession>> completeQnASession(
    String sessionId,
  ) async {
    try {
      final session = await remoteDataSource.completeQnASession(sessionId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QnASession>> getQnASession(String sessionId) async {
    try {
      final session = await remoteDataSource.getQnASession(sessionId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
