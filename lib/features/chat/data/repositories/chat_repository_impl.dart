import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/firebase_realtime_chat_datasource.dart';
import '../models/chat_model.dart' as data;

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseRealtimeChatDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<List<ChatEntity>> getUserChats() {
    return remoteDataSource.getUserChats().map((chatModels) {
      return chatModels.map((model) => _mapChatModelToEntity(model)).toList();
    });
  }

  @override
  Future<Either<Failure, ChatEntity>> getChatById(String chatId) async {
    if (await networkInfo.isConnected) {
      try {
        final chatModel = await remoteDataSource.getChatById(chatId);
        if (chatModel != null) {
          return Right(_mapChatModelToEntity(chatModel));
        } else {
          return Left(ServerFailure('Chat not found'));
        }
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> createChat(
    List<String> participantIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final chatId = await remoteDataSource.createChat(participantIds);
        return Right(chatId);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String?>> getExistingChatId(String otherUserId) async {
    if (await networkInfo.isConnected) {
      try {
        final chatId = await remoteDataSource.getExistingChatId(otherUserId);
        return Right(chatId);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat(String chatId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteChat(chatId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Stream<List<MessageEntity>> getChatMessages(String chatId) {
    return remoteDataSource.getChatMessages(chatId).map((messageModels) {
      return messageModels
          .map((model) => _mapMessageModelToEntity(model))
          .toList();
    });
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    MessageType type = MessageType.text,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendMessage(
          chatId,
          text,
          type: _mapDomainMessageTypeToData(type),
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsSeen(
    String chatId,
    String messageId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markMessageAsSeen(chatId, messageId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markLastMessageAsSeen(String chatId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markLastMessageAsSeen(chatId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(
    String chatId,
    String messageId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteMessage(chatId, messageId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setTypingStatus(chatId, userId, isTyping);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Stream<bool> isOtherUserTyping(String chatId, String otherUserId) {
    return remoteDataSource.isOtherUserTyping(chatId, otherUserId);
  }

  @override
  Future<Either<Failure, void>> setChatDeletionFlag(
    String chatId,
    String userId,
    int messageIndex,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setChatDeletionFlag(
          chatId,
          userId,
          messageIndex,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, int?>> getChatDeletionFlag(
    String chatId,
    String userId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getChatDeletionFlag(
          chatId,
          userId,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(
    String userId,
    String blockedUserId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.blockUser(userId, blockedUserId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserBlocked(
    String userId,
    String blockedUserId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.isUserBlocked(
          userId,
          blockedUserId,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // Helper methods to map between models and entities
  ChatEntity _mapChatModelToEntity(data.ChatModel model) {
    return ChatEntity(
      id: model.id,
      participants: model.participants,
      lastText: model.lastText,
      lastTextTime: model.lastTextTime,
      lastTextBy: model.lastTextBy,
      isLastTextSeen: model.isLastTextSeen,
      createdAt: model.createdAt,
      isUnread:
          model.isLastTextSeen == false &&
          model.lastTextBy != remoteDataSource.currentUserId,
    );
  }

  MessageEntity _mapMessageModelToEntity(data.MessageModel model) {
    return MessageEntity(
      id: model.id,
      text: model.text,
      senderId: model.senderId,
      timestamp: model.timestamp,
      type: _mapDataMessageTypeToDomain(model.type),
      isSeen: model.isSeen,
      mediaUrl: model.mediaUrl,
      mediaType: model.mediaType,
    );
  }

  // Helper methods to map between MessageType enums
  data.MessageType _mapDomainMessageTypeToData(MessageType domainType) {
    switch (domainType) {
      case MessageType.text:
        return data.MessageType.text;
      case MessageType.image:
        return data.MessageType.image;
      case MessageType.video:
        return data.MessageType.video;
      case MessageType.audio:
        return data.MessageType.audio;
      case MessageType.file:
        return data.MessageType.file;
    }
  }

  MessageType _mapDataMessageTypeToDomain(data.MessageType dataType) {
    switch (dataType) {
      case data.MessageType.text:
        return MessageType.text;
      case data.MessageType.image:
        return MessageType.image;
      case data.MessageType.video:
        return MessageType.video;
      case data.MessageType.audio:
        return MessageType.audio;
      case data.MessageType.file:
        return MessageType.file;
    }
  }
}
