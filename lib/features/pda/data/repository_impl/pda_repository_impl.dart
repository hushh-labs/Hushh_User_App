import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_response.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

class PdaRepositoryImpl implements PdaRepository {
  final PdaDataSource dataSource;

  PdaRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<PdaMessage>>> getMessages(String userId) async {
    try {
      final messages = await dataSource.getMessages(userId);
      return Right(
        messages.map<PdaMessage>((model) => model.toDomain()).toList(),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMessage(PdaMessage message) async {
    try {
      final model = PdaMessageModel.fromDomain(message);
      await dataSource.saveMessage(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await dataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearMessages(String userId) async {
    try {
      await dataSource.clearMessages(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PdaResponse>> sendToVertexAI(
    String message,
    List<PdaMessage> context, {
    List<File>? imageFiles,
  }) async {
    try {
      final contextModels = context
          .map((msg) => PdaMessageModel.fromDomain(msg))
          .toList();
      final response = await dataSource.sendToVertexAI(
        message,
        contextModels,
        imageFiles: imageFiles,
      );
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> prewarmUserContext(String hushhId) async {
    try {
      await dataSource.prewarmUserContext(hushhId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserContext(
    String hushhId,
  ) async {
    try {
      final context = await dataSource.getUserContext(hushhId);
      return Right(context);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> searchRelevantMessages(
    String userId,
    String query, {
    int topK = 5,
    double similarityThreshold = 0.5,
  }) async {
    try {
      // For now, return empty results as vector search is not implemented
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  searchRelevantMessagesDetailed(
    String userId,
    String query, {
    int topK = 5,
  }) async {
    try {
      // For now, return empty results as vector search is not implemented
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserDataToVectorStore(String userId) async {
    try {
      // For now, do nothing as vector store is not implemented
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
