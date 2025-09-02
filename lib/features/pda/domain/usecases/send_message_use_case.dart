import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:uuid/uuid.dart';

class PdaSendMessageUseCase {
  final PdaRepository repository;

  PdaSendMessageUseCase(this.repository);

  Future<Either<Failure, PdaMessage>> call({
    required String hushhId,
    required String message,
    required List<PdaMessage> context,
  }) async {
    // Save user message first
    final userMessage = PdaMessage(
      id: const Uuid().v4(),
      hushhId: hushhId,
      content: message,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    final saveUserResult = await repository.saveMessage(userMessage);
    if (saveUserResult.isLeft()) {
      return Left(
        saveUserResult.fold((error) => error, (r) => throw Exception()),
      );
    }

    // Send to Vertex AI Claude and get response
    final vertexAiResult = await repository.sendToVertexAI(message, context);
    if (vertexAiResult.isLeft()) {
      return Left(
        vertexAiResult.fold((error) => error, (r) => throw Exception()),
      );
    }

    final vertexAiResponse = vertexAiResult.fold(
      (error) => throw Exception(),
      (response) => response,
    );

    // Save AI response
    final aiMessage = PdaMessage(
      id: const Uuid().v4(),
      hushhId: hushhId,
      content: vertexAiResponse,
      isFromUser: false,
      timestamp: DateTime.now(),
    );

    final saveAiResult = await repository.saveMessage(aiMessage);
    if (saveAiResult.isLeft()) {
      return Left(
        saveAiResult.fold((error) => error, (r) => throw Exception()),
      );
    }

    return Right(aiMessage);
  }
}
