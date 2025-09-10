import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
    List<File>? imageFiles,
    List<String>? imageUrls,
  }) async {
    // Save user message first
    final userMessage = PdaMessage(
      id: const Uuid().v4(),
      hushhId: hushhId,
      content: message.isEmpty
          ? '[${imageFiles?.length ?? 0} Image${(imageFiles?.length ?? 0) > 1 ? 's' : ''}]'
          : message,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: (imageFiles?.isNotEmpty ?? false)
          ? MessageType.image
          : MessageType.text,
      metadata: (imageUrls != null && imageUrls.isNotEmpty)
          ? imageUrls.join('|')
          : (imageFiles?.isNotEmpty == true
                ? imageFiles!.map((f) => f.path).join('|')
                : null),
    );

    final saveUserResult = await repository.saveMessage(userMessage);
    if (saveUserResult.isLeft()) {
      return Left(
        saveUserResult.fold((error) => error, (r) => throw Exception()),
      );
    }

    // Send to Vertex AI Claude and get response
    debugPrint(
      '🔍 [SEND MESSAGE] Sending to Vertex AI with ${imageFiles?.length ?? 0} images',
    );
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (int i = 0; i < imageFiles.length; i++) {
        debugPrint('🔍 [SEND MESSAGE] Image ${i + 1}: ${imageFiles[i].path}');
      }
    }

    final vertexAiResult = await repository.sendToVertexAI(
      message,
      context,
      imageFiles: imageFiles,
    );
    if (vertexAiResult.isLeft()) {
      return Left(
        vertexAiResult.fold((error) => error, (r) => throw Exception()),
      );
    }

    final vertexAiResponse = vertexAiResult.fold(
      (error) => throw Exception(),
      (response) => response,
    );

    // Save AI response with cost information
    final aiMessage = PdaMessage(
      id: const Uuid().v4(),
      hushhId: hushhId,
      content: vertexAiResponse.content,
      isFromUser: false,
      timestamp: DateTime.now(),
      cost: vertexAiResponse.cost,
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
