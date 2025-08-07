import 'package:dartz/dartz.dart';
import '../entities/chat_entity.dart';
import '../entities/user_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class ChatRepository {
  // Chat operations
  Stream<List<ChatEntity>> getUserChats();
  Future<Either<Failure, ChatEntity>> getChatById(String chatId);
  Future<Either<Failure, String>> createChat(List<String> participantIds);
  Future<Either<Failure, String?>> getExistingChatId(String otherUserId);
  Future<Either<Failure, void>> deleteChat(String chatId);

  // Message operations
  Stream<List<MessageEntity>> getChatMessages(String chatId);
  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    MessageType type = MessageType.text,
  });
  Future<Either<Failure, void>> markMessageAsSeen(
    String chatId,
    String messageId,
  );
  Future<Either<Failure, void>> markLastMessageAsSeen(String chatId);
  Future<Either<Failure, void>> deleteMessage(String chatId, String messageId);

  // Typing status operations
  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  );
  Stream<bool> isOtherUserTyping(String chatId, String otherUserId);

  // Chat deletion and blocking operations
  Future<Either<Failure, void>> setChatDeletionFlag(
    String chatId,
    String userId,
    int messageIndex,
  );
  Future<Either<Failure, int?>> getChatDeletionFlag(
    String chatId,
    String userId,
  );
  Future<Either<Failure, void>> blockUser(String userId, String blockedUserId);
  Future<Either<Failure, bool>> isUserBlocked(
    String userId,
    String blockedUserId,
  );

  // User information operations
  Future<Either<Failure, String>> getUserDisplayName(String userId);

  // User operations
  Future<Either<Failure, List<ChatUserEntity>>> getUsers();
  Future<Either<Failure, ChatUserEntity?>> getCurrentUser();
  Future<Either<Failure, List<ChatUserEntity>>> searchUsers(String query);
}
