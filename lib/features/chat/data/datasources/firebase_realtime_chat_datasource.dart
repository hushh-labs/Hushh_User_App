import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class FirebaseRealtimeChatDataSource {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all chats for current user
  Stream<List<ChatModel>> getUserChats() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _database.child('chats').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries
          .where((entry) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            final participants = List<String>.from(
              chatData['participants'] ?? [],
            );
            return participants.contains(userId);
          })
          .map((entry) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            return ChatModel.fromJson(entry.key.toString(), chatData);
          })
          .toList();
    });
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];

          return data.entries.map((entry) {
            final messageData = Map<String, dynamic>.from(entry.value as Map);
            return MessageModel.fromJson(entry.key.toString(), messageData);
          }).toList();
        });
  }

  // Send a message
  Future<void> sendMessage(
    String chatId,
    String text, {
    MessageType type = MessageType.text,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Sending message to chat: $chatId');
    print('Message text: $text');
    print('User ID: $userId');

    final messageRef = _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .push();

    final message = MessageModel(
      id: messageRef.key!,
      text: text,
      senderId: userId,
      timestamp: DateTime.now(),
      type: type,
      isSeen: false,
    );

    // Save message
    await messageRef.set(message.toJson());
    print('Message saved successfully');

    // Update chat's last message info
    await _database.child('chats').child(chatId).update({
      'lastText': text,
      'lastTextTime': DateTime.now().millisecondsSinceEpoch,
      'lastTextBy': userId,
      'isLastTextSeen': false,
    });
    print('Chat last message info updated successfully');
  }

  // Set typing status
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await _database
        .child('chats')
        .child(chatId)
        .child('typingStatus')
        .child(userId)
        .set(isTyping);
  }

  // Listen for typing status of the other user
  Stream<bool> isOtherUserTyping(String chatId, String otherUserId) {
    return _database
        .child('chats')
        .child(chatId)
        .child('typingStatus')
        .child(otherUserId)
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  // Set chat deletion flag for a user
  Future<void> setChatDeletionFlag(
    String chatId,
    String userId,
    int messageIndex,
  ) async {
    await _database
        .child('chats')
        .child(chatId)
        .child('deletionFlags')
        .child(userId)
        .set(messageIndex);
  }

  // Get chat deletion flag for a user
  Future<int?> getChatDeletionFlag(String chatId, String userId) async {
    final snapshot = await _database
        .child('chats')
        .child(chatId)
        .child('deletionFlags')
        .child(userId)
        .get();

    return snapshot.value as int?;
  }

  // Block a user
  Future<void> blockUser(String userId, String blockedUserId) async {
    await _database
        .child('users')
        .child(userId)
        .child('blockedUsers')
        .child(blockedUserId)
        .set(true);
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userId, String blockedUserId) async {
    final snapshot = await _database
        .child('users')
        .child(userId)
        .child('blockedUsers')
        .child(blockedUserId)
        .get();

    return snapshot.value == true;
  }

  // Create a new chat
  Future<String> createChat(List<String> participantIds) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Creating chat with participants: $participantIds');
    print('Current user ID: $userId');

    // Add current user to participants if not already included
    if (!participantIds.contains(userId)) {
      participantIds.add(userId);
    }

    // Sort participant IDs to ensure consistent chat ID
    participantIds.sort();

    // Create chat ID as concatenation of sorted user IDs
    final chatId = participantIds.join('_');
    print('Generated chat ID: $chatId');

    // Create participants map
    final participants = <String, bool>{};
    for (final id in participantIds) {
      participants[id] = true;
    }

    final chat = ChatModel(
      id: chatId,
      participants: participantIds,
      createdAt: DateTime.now(),
    );

    // Create the chat with initial structure including typingStatus and deletionFlags
    final chatData = chat.toJson();

    // Initialize typingStatus with participant IDs as keys, set to false
    final typingStatus = <String, bool>{};
    for (final participantId in participantIds) {
      typingStatus[participantId] = false;
    }
    chatData['typingStatus'] = typingStatus;

    // Initialize deletionFlags with participant IDs as keys, set to -1 (no deletion)
    final deletionFlags = <String, int>{};
    for (final participantId in participantIds) {
      deletionFlags[participantId] = -1; // -1 means no deletion
    }
    chatData['deletionFlags'] = deletionFlags;

    // Initialize hasBlocked with participant IDs as keys, set to false
    final hasBlocked = <String, bool>{};
    for (final participantId in participantIds) {
      hasBlocked[participantId] = false;
    }
    chatData['hasBlocked'] = hasBlocked;

    print('Creating chat with data: $chatData');
    await _database.child('chats').child(chatId).set(chatData);
    print(
      'Chat created successfully with typingStatus, deletionFlags, and hasBlocked',
    );
    return chatId;
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    await _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .child(messageId)
        .update({'isSeen': true});
  }

  // Mark last message as seen
  Future<void> markLastMessageAsSeen(String chatId) async {
    await _database.child('chats').child(chatId).update({
      'isLastTextSeen': true,
    });
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .child(messageId)
        .remove();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    await _database.child('chats').child(chatId).remove();
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final snapshot = await _database.child('chats').child(chatId).get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return ChatModel.fromJson(chatId, data);
  }

  // Check if chat exists between two users
  Future<String?> getExistingChatId(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    // Create the expected chat ID using the same logic as createChat
    final participants = [userId, otherUserId]..sort();
    final expectedChatId = participants.join('_');

    // Check if the chat exists
    final snapshot = await _database.child('chats').child(expectedChatId).get();

    if (snapshot.exists) {
      return expectedChatId;
    }

    return null;
  }
}
