import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_response.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

abstract class PdaRepository {
  Future<Either<Failure, List<PdaMessage>>> getMessages(String userId);
  Future<Either<Failure, void>> saveMessage(PdaMessage message);
  Future<Either<Failure, void>> deleteMessage(String messageId);
  Future<Either<Failure, void>> clearMessages(String userId);
  Future<Either<Failure, PdaResponse>> sendToVertexAI(
    String message,
    List<PdaMessage> context, {
    List<File>? imageFiles,
  });
  Future<Either<Failure, void>> prewarmUserContext(String hushhId);
  Future<Either<Failure, Map<String, dynamic>>> getUserContext(String hushhId);

  // Vector search methods for enhanced chat memory
  Future<Either<Failure, List<String>>> searchRelevantMessages(
    String userId,
    String query, {
    int topK = 5,
    double similarityThreshold = 0.5,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>>
  searchRelevantMessagesDetailed(String userId, String query, {int topK = 5});

  // Save user's personal data to vector store for comprehensive search
  Future<Either<Failure, void>> saveUserDataToVectorStore(String userId);
}
