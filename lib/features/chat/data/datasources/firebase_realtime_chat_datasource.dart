import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class FirebaseRealtimeChatDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseRealtimeChatDataSource() {
    print('FirebaseRealtimeChatDataSource initialized (using Firestore)');

    // Set up auth state listener
    _auth.authStateChanges().listen((user) {
      print('Auth state changed - User: ${user?.uid}');
      if (user != null) {
        print('User authenticated for database access');
      } else {
        print('User not authenticated for database access');
      }
    });
  }

  // Get current user ID
  String? get currentUserId {
    final user = _auth.currentUser;
    print('Current user: ${user?.uid}');
    print('User is authenticated: ${user != null}');
    print('User email: ${user?.email}');
    return user?.uid;
  }

  // Get all chats for current user (Firestore) - REALTIME
  Stream<List<ChatModel>> getUserChats() {
    final userId = currentUserId;
    if (userId == null) {
      print('❌ DataSource: No current user ID available for real-time chats.');
      return Stream.value([]);
    }

    print(
      '🔍 DataSource: Subscribing to real-time chat updates for user: $userId',
    );

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          print(
            '🔍 DataSource: Received snapshot with ${snapshot.docs.length} chats.',
          );
          final chats = snapshot.docs
              .map((doc) {
                try {
                  final data = Map<String, dynamic>.from(doc.data());
                  print('🔍 DataSource: Processing chat doc: ${doc.id}');

                  // Normalize timestamps to ms integers for ChatModel.fromJson
                  if (data['createdAt'] is Timestamp) {
                    data['createdAt'] =
                        (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
                  }
                  if (data['lastTextTime'] is Timestamp) {
                    data['lastTextTime'] = (data['lastTextTime'] as Timestamp)
                        .millisecondsSinceEpoch;
                  }

                  return ChatModel.fromJson(doc.id, data);
                } catch (e) {
                  print('❌ DataSource: Error mapping chat doc ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ChatModel>()
              .toList(); // Filter out any nulls from errors

          // Sort by last message time, descending
          chats.sort((a, b) {
            final timeA = a.lastTextTime ?? a.createdAt;
            final timeB = b.lastTextTime ?? b.createdAt;
            return timeB.compareTo(timeA);
          });

          print('🔍 DataSource: Emitting ${chats.length} sorted chats.');
          return chats;
        })
        .handleError((error) {
          print('❌ DataSource: Error in getUserChats stream: $error');
          return <ChatModel>[];
        });
  }

  // Get messages for a specific chat (Firestore)
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    print(
      '🔍 DataSource: Subscribing to messages for chat: $chatId (Firestore)',
    );
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] =
                  (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
            }
            return MessageModel.fromJson(doc.id, data);
          }).toList();
          return messages;
        });
  }

  // Get chat messages with auto-seen functionality
  Stream<List<MessageModel>> getChatMessagesWithAutoSeen(String chatId) {
    final currentUserId = this.currentUserId;
    print('🔍 DataSource: getChatMessagesWithAutoSeen for chat: $chatId');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          print('🔍 DataSource: Processing ${snapshot.docs.length} messages');
          final messages = <MessageModel>[];

          for (final doc in snapshot.docs) {
            final data = Map<String, dynamic>.from(doc.data());

            // Auto-mark messages from other users as seen
            final senderId = data['senderId'] as String;
            final isSeen = data['isSeen'] as bool;

            if (senderId != currentUserId && !isSeen) {
              print(
                '🔍 DataSource: Auto-marking message ${doc.id} as seen (sender: $senderId)',
              );

              // Mark message as seen
              doc.reference.update({'isSeen': true});

              // Update chat's isLastTextSeen if this is the latest message
              _updateChatLastTextSeen(chatId, data);
            }

            // Convert to MessageModel
            final messageModel = MessageModel.fromJson(doc.id, data);
            messages.add(messageModel);
          }

          print('🔍 DataSource: Returning ${messages.length} messages');
          return messages;
        });
  }

  Future<void> _updateChatLastTextSeen(
    String chatId,
    Map<String, dynamic> messageData,
  ) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData != null) {
        final lastTextTime = chatData['lastTextTime'] as int;
        final messageTimestamp = messageData['timestamp'] as int;

        // If this message is the latest, update isLastTextSeen
        if (messageTimestamp >= lastTextTime) {
          print('🔍 DataSource: Updating chat $chatId isLastTextSeen to true');
          await _firestore.collection('chats').doc(chatId).update({
            'isLastTextSeen': true,
          });
        }
      }
    } catch (e) {
      print('❌ DataSource: Error updating chat lastTextSeen: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(
    String chatId,
    String text, {
    MessageType type = MessageType.text,
  }) async {
    // Wait for auth to be ready
    await _auth.authStateChanges().first;

    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Sending message to chat: $chatId');
    print('Message text: $text');
    print('User ID: $userId');

    try {
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: msgRef.id,
        text: text,
        senderId: userId,
        timestamp: DateTime.now(),
        type: type,
        isSeen: false,
      );

      await msgRef.set(message.toJson());
      await _firestore.collection('chats').doc(chatId).update({
        'lastText': text,
        'lastTextTime': DateTime.now().millisecondsSinceEpoch,
        'lastTextBy': userId,
        'isLastTextSeen': false,
      });
      print('Message saved and chat updated successfully (Firestore)');
    } catch (e) {
      print('Error sending message: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Set typing status
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  // Listen for typing status of the other user
  Stream<bool> isOtherUserTyping(String chatId, String otherUserId) {
    print(
      '🔍 DataSource: Subscribing to typingStatus (Firestore) for chat: $chatId otherUser: $otherUserId',
    );
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return false;
      final typing = data['typingStatus'];
      if (typing is Map<String, dynamic>) {
        return typing[otherUserId] == true;
      }
      return false;
    });
  }

  // Set chat deletion flag for a user
  Future<void> setChatDeletionFlag(
    String chatId,
    String userId,
    int messageIndex,
  ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'deletionFlags.$userId': messageIndex,
    });
  }

  // Get chat deletion flag for a user
  Future<int?> getChatDeletionFlag(String chatId, String userId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    final data = doc.data();
    if (data == null) return null;
    final flags = data['deletionFlags'];
    if (flags is Map<String, dynamic>) {
      final val = flags[userId];
      if (val is int) return val;
    }
    return null;
  }

  // Block a user using hasBlocked field in chat document
  Future<void> blockUser(String userId, String blockedUserId) async {
    final chatId = await getExistingChatId(blockedUserId);
    if (chatId != null) {
      await _firestore.collection('chats').doc(chatId).update({
        'hasBlocked.$userId': true,
      });
    }
  }

  // Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId) async {
    final chatId = await getExistingChatId(blockedUserId);
    if (chatId != null) {
      await _firestore.collection('chats').doc(chatId).update({
        'hasBlocked.$userId': false,
      });
    }
  }

  // Check if a user is blocked using hasBlocked field in chat document
  Future<bool> isUserBlocked(String userId, String blockedUserId) async {
    // Find the chat between these two users
    final chatId = await getExistingChatId(blockedUserId);
    if (chatId == null) return false;

    final doc = await _firestore.collection('chats').doc(chatId).get();
    final data = doc.data();
    if (data == null) return false;

    final hasBlocked = data['hasBlocked'];
    if (hasBlocked is Map<String, dynamic>) {
      return hasBlocked[userId] == true;
    }
    return false;
  }

  // Create a new chat
  Future<String> createChat(List<String> participantIds) async {
    // Wait for auth to be ready
    await _auth.authStateChanges().first;

    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Creating chat with participants: $participantIds');
    print('Current user ID: $userId');

    // Firestore has no separate connectivity test here

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

    print('Creating chat with data: $chatData (Firestore)');
    try {
      await _firestore.collection('chats').doc(chatId).set(chatData);
      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isSeen': true});
  }

  // Mark last message as seen
  Future<void> markLastMessageAsSeen(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isLastTextSeen': true,
    });
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).delete();
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    if (data['lastTextTime'] is Timestamp) {
      data['lastTextTime'] =
          (data['lastTextTime'] as Timestamp).millisecondsSinceEpoch;
    }
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
    final doc = await _firestore.collection('chats').doc(expectedChatId).get();
    if (doc.exists) return expectedChatId;
    return null;
  }

  // Get user display name from Firestore
  Future<String> getUserDisplayName(String userId) async {
    print('🔍 DataSource: Fetching display name for user: $userId');
    try {
      // First try to get user from HushUsers collection
      final userDoc = await FirebaseFirestore.instance
          .collection('HushUsers')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userName =
            userData['fullName'] ??
            userData['name'] ??
            userData['displayName'] ??
            'Unknown User';
        print('🔍 DataSource: Found user in HushUsers: $userName');
        return userName;
      }

      // If not found in HushUsers, try Hushhagents collection
      print('🔍 DataSource: User not found in HushUsers, trying Hushhagents');
      final agentDoc = await FirebaseFirestore.instance
          .collection('Hushhagents')
          .doc(userId)
          .get();

      if (agentDoc.exists) {
        final agentData = agentDoc.data()!;
        final agentName =
            agentData['fullName'] ?? agentData['name'] ?? 'Unknown Agent';
        print('🔍 DataSource: Found user in Hushhagents: $agentName');
        return agentName;
      }

      // If not found in either collection, use a shortened user ID
      print(
        '🔍 DataSource: User not found in either collection, using fallback',
      );
      if (userId.length > 8) {
        return 'User ${userId.substring(0, 8)}...';
      }
      return 'User $userId';
    } catch (e) {
      // On error, fallback to shortened user ID
      print('🔍 DataSource: Error fetching user name: $e');
      if (userId.length > 8) {
        return 'User ${userId.substring(0, 8)}...';
      }
      return 'User $userId';
    }
  }

  // Get all users from Firestore
  Future<List<ChatUserModel>> getUsers() async {
    final List<ChatUserModel> allUsers = [];
    final currentUser = this.currentUserId;

    try {
      // Get users from HushUsers collection
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('HushUsers')
          .get();

      final usersFromHushUsers = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatUserModel.fromJson(doc.id, data);
      }).toList();

      allUsers.addAll(usersFromHushUsers);

      // Get users from Hushhagents collection
      final agentsSnapshot = await FirebaseFirestore.instance
          .collection('Hushhagents')
          .get();

      final usersFromHushhagents = agentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatUserModel.fromJson(doc.id, data);
      }).toList();

      allUsers.addAll(usersFromHushhagents);

      // Filter out current user
      allUsers.removeWhere((user) => user.id == currentUser);

      // Sort by creation date (latest first)
      allUsers.sort((a, b) {
        final dateA =
            a.createdAt ?? DateTime.now().subtract(const Duration(days: 365));
        final dateB =
            b.createdAt ?? DateTime.now().subtract(const Duration(days: 365));
        return dateB.compareTo(dateA);
      });

      return allUsers;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get current user
  Future<ChatUserModel?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Try to get from HushUsers first
      final userDoc = await FirebaseFirestore.instance
          .collection('HushUsers')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return ChatUserModel.fromJson(userId, userDoc.data()!);
      }

      // Try to get from Hushhagents
      final agentDoc = await FirebaseFirestore.instance
          .collection('Hushhagents')
          .doc(userId)
          .get();

      if (agentDoc.exists) {
        return ChatUserModel.fromJson(userId, agentDoc.data()!);
      }

      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  // Search users
  Future<List<ChatUserModel>> searchUsers(String query) async {
    final allUsers = await getUsers();
    if (query.isEmpty) return allUsers;

    final lowercaseQuery = query.toLowerCase();
    return allUsers.where((user) {
      final name = user.name?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final phone = user.phoneNumber?.toLowerCase() ?? '';

      return name.contains(lowercaseQuery) ||
          email.contains(lowercaseQuery) ||
          phone.contains(lowercaseQuery);
    }).toList();
  }

  // Mark chat as seen when opening it
  Future<void> markChatAsSeen(String chatId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) {
      print('❌ DataSource: No current user ID available for markChatAsSeen');
      return;
    }

    print('🔍 DataSource: markChatAsSeen called for chat: $chatId');

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData != null) {
        final lastTextBy = chatData['lastTextBy'] as String;
        final isLastTextSeen = chatData['isLastTextSeen'] as bool;

        print(
          '🔍 DataSource: Chat $chatId - lastTextBy: $lastTextBy, isLastTextSeen: $isLastTextSeen',
        );

        // If last message was sent by other user and not seen, mark as seen
        if (lastTextBy != currentUserId && !isLastTextSeen) {
          print(
            '🔍 DataSource: Marking chat $chatId as seen (lastTextBy: $lastTextBy)',
          );
          await _firestore.collection('chats').doc(chatId).update({
            'isLastTextSeen': true,
          });
        } else {
          print(
            '🔍 DataSource: Chat $chatId already seen or last message is from current user',
          );
        }
      }
    } catch (e) {
      print('❌ DataSource: Error marking chat as seen: $e');
    }
  }

  Future<bool> areUsersActive(List<String> userIds) async {
    if (userIds.length < 2) return false;

    try {
      for (final userId in userIds) {
        final userDoc =
            await _firestore.collection('HushUsers').doc(userId).get();
        if (userDoc.exists) continue;

        final agentDoc =
            await _firestore.collection('Hushhagents').doc(userId).get();
        if (!agentDoc.exists) {
          print('User not found: $userId');
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking if users are active: $e');
      return false;
    }
  }
}
