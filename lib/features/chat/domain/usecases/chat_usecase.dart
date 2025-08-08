import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_entity.dart';
import '../entities/user_entity.dart';
import '../repositories/chat_repository.dart';

// Get User Chats Use Case
class GetUserChats extends UseCase<List<ChatEntity>, NoParams> {
  final ChatRepository repository;

  GetUserChats(this.repository);

  @override
  Future<Either<Failure, List<ChatEntity>>> call(NoParams params) async {
    try {
      // For now, we'll return an empty list since streams need special handling
      // In a real implementation, you might want to create a separate StreamUseCase
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Get Chat Messages Use Case
class GetChatMessages extends UseCase<List<MessageEntity>, String> {
  final ChatRepository repository;

  GetChatMessages(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(String chatId) async {
    try {
      // For now, we'll return an empty list since streams need special handling
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Send Message Use Case
class SendMessage extends UseCase<void, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      params.chatId,
      params.text,
      type: params.type,
    );
  }
}

class SendMessageParams extends Equatable {
  final String chatId;
  final String text;
  final MessageType type;

  const SendMessageParams({
    required this.chatId,
    required this.text,
    this.type = MessageType.text,
  });

  @override
  List<Object> get props => [chatId, text, type];
}

// Create Chat Use Case
class CreateChat extends UseCase<String, List<String>> {
  final ChatRepository repository;

  CreateChat(this.repository);

  @override
  Future<Either<Failure, String>> call(List<String> participantIds) async {
    return await repository.createChat(participantIds);
  }
}

// Get Existing Chat ID Use Case
class GetExistingChatId extends UseCase<String?, String> {
  final ChatRepository repository;

  GetExistingChatId(this.repository);

  @override
  Future<Either<Failure, String?>> call(String otherUserId) async {
    return await repository.getExistingChatId(otherUserId);
  }
}

// Get Chat By ID Use Case
class GetChatById extends UseCase<ChatEntity?, String> {
  final ChatRepository repository;

  GetChatById(this.repository);

  @override
  Future<Either<Failure, ChatEntity?>> call(String chatId) async {
    return await repository.getChatById(chatId);
  }
}

// Set Typing Status Use Case
class SetTypingStatus extends UseCase<void, SetTypingStatusParams> {
  final ChatRepository repository;

  SetTypingStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(SetTypingStatusParams params) async {
    return await repository.setTypingStatus(
      params.chatId,
      params.userId,
      params.isTyping,
    );
  }
}

class SetTypingStatusParams extends Equatable {
  final String chatId;
  final String userId;
  final bool isTyping;

  const SetTypingStatusParams({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatId, userId, isTyping];
}

// Mark Message As Seen Use Case
class MarkMessageAsSeen extends UseCase<void, MarkMessageAsSeenParams> {
  final ChatRepository repository;

  MarkMessageAsSeen(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkMessageAsSeenParams params) async {
    return await repository.markMessageAsSeen(params.chatId, params.messageId);
  }
}

class MarkMessageAsSeenParams extends Equatable {
  final String chatId;
  final String messageId;

  const MarkMessageAsSeenParams({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatId, messageId];
}

// Mark Last Message As Seen Use Case
class MarkLastMessageAsSeen extends UseCase<void, String> {
  final ChatRepository repository;

  MarkLastMessageAsSeen(this.repository);

  @override
  Future<Either<Failure, void>> call(String chatId) async {
    return await repository.markLastMessageAsSeen(chatId);
  }
}

// Stream Use Cases (for real-time features)
class StreamUserChats {
  final ChatRepository repository;

  StreamUserChats(this.repository);

  Stream<List<ChatEntity>> call() {
    print('🔍 UseCase: StreamUserChats.call() called');
    final stream = repository.getUserChats();
    print('🔍 UseCase: Got stream from repository');

    return stream
        .map((entities) {
          print(
            '🔍 UseCase: Stream.map called with ${entities.length} entities',
          );
          print(
            '🔍 UseCase: Entity IDs: ${entities.map((e) => e.id).join(', ')}',
          );
          return entities;
        })
        .handleError((error) {
          print('❌ UseCase: Error in StreamUserChats: $error');
          return <ChatEntity>[];
        });
  }
}

class StreamChatMessages {
  final ChatRepository repository;

  StreamChatMessages(this.repository);

  Stream<List<MessageEntity>> call(String chatId) {
    return repository.getChatMessages(chatId);
  }
}

class StreamTypingStatus {
  final ChatRepository repository;

  StreamTypingStatus(this.repository);

  Stream<bool> call(String chatId, String otherUserId) {
    return repository.isOtherUserTyping(chatId, otherUserId);
  }
}

// Get User Display Name Use Case
class GetUserDisplayName extends UseCase<String, String> {
  final ChatRepository repository;

  GetUserDisplayName(this.repository);

  @override
  Future<Either<Failure, String>> call(String userId) async {
    return await repository.getUserDisplayName(userId);
  }
}

// Get Users Use Case
class GetUsers extends UseCase<List<ChatUserEntity>, NoParams> {
  final ChatRepository repository;

  GetUsers(this.repository);

  @override
  Future<Either<Failure, List<ChatUserEntity>>> call(NoParams params) async {
    return await repository.getUsers();
  }
}

// Get Current User Use Case
class GetCurrentUser extends UseCase<ChatUserEntity?, NoParams> {
  final ChatRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, ChatUserEntity?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

// Search Users Use Case
class SearchUsers extends UseCase<List<ChatUserEntity>, String> {
  final ChatRepository repository;

  SearchUsers(this.repository);

  @override
  Future<Either<Failure, List<ChatUserEntity>>> call(String query) async {
    return await repository.searchUsers(query);
  }
}
