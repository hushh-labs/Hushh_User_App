import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class FirebaseRealtimeChatDataSource {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseRealtimeChatDataSource() {
    print('FirebaseRealtimeChatDataSource initialized');
    print('Database URL: ${FirebaseDatabase.instance.databaseURL}');
    print('Database reference path: ${_database.path}');

    // Set up auth state listener for database
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

  // Get all chats for current user
  Stream<List<ChatModel>> getUserChats() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    print('Getting chats for user: $userId');
    print('Database path: ${_database.child('chats').path}');

    return _database.child('chats').onValue.map((event) {
      print('Stream event received');
      print('Event snapshot value: ${event.snapshot.value}');
      print('Event snapshot exists: ${event.snapshot.exists}');

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('No data in snapshot, returning empty list');
        return [];
      }

      print('Raw data entries: ${data.entries.length}');

      final filteredChats = data.entries
          .where((entry) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            final participants = List<String>.from(
              chatData['participants'] ?? [],
            );
            final containsUser = participants.contains(userId);
            print(
              'Chat ${entry.key} participants: $participants, contains user: $containsUser',
            );
            return containsUser;
          })
          .map((entry) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            print('Creating ChatModel for chat: ${entry.key}');
            return ChatModel.fromJson(entry.key.toString(), chatData);
          })
          .toList();

      print('Filtered chats count: ${filteredChats.length}');
      return filteredChats;
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
    // Wait for auth to be ready
    await _auth.authStateChanges().first;

    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Sending message to chat: $chatId');
    print('Message text: $text');
    print('User ID: $userId');

    try {
      // Check if chat exists first
      final chatSnapshot = await _database.child('chats').child(chatId).get();
      print('Chat existence check - snapshot value: ${chatSnapshot.value}');
      print('Chat existence check - snapshot exists: ${chatSnapshot.exists}');

      final messageRef = _database
          .child('chats')
          .child(chatId)
          .child('messages')
          .push();

      print('Message reference path: ${messageRef.path}');
      print('Message reference key: ${messageRef.key}');

      final message = MessageModel(
        id: messageRef.key!,
        text: text,
        senderId: userId,
        timestamp: DateTime.now(),
        type: type,
        isSeen: false,
      );

      print('Message data to save: ${message.toJson()}');

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

      // Verify message was saved
      final messageSnapshot = await messageRef.get();
      print('Message verification - snapshot value: ${messageSnapshot.value}');
      print(
        'Message verification - snapshot exists: ${messageSnapshot.exists}',
      );
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
    // Wait for auth to be ready
    await _auth.authStateChanges().first;

    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('Creating chat with participants: $participantIds');
    print('Current user ID: $userId');

    // Test database connection first
    try {
      print('Testing database read access...');
      print('Current user ID: $userId');
      print('User is authenticated: ${_auth.currentUser != null}');

      // Check if user has a valid token
      final token = await _auth.currentUser?.getIdToken();
      print('User has valid token: ${token != null}');

      final testSnapshot = await _database.child('chats').get();
      print(
        'Database read test successful - snapshot exists: ${testSnapshot.exists}',
      );
    } catch (e) {
      print('Database read test failed: $e');
      print('Error details: ${e.toString()}');
      rethrow;
    }

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
    print('Database reference: ${_database.child('chats').child(chatId).path}');

    try {
      print('About to call set() operation...');
      await _database.child('chats').child(chatId).set(chatData);
      print('set() operation completed');
      print(
        'Chat created successfully with typingStatus, deletionFlags, and hasBlocked',
      );

      print('About to verify chat creation...');
      // Verify the chat was created
      final snapshot = await _database.child('chats').child(chatId).get();
      print('Verification snapshot value: ${snapshot.value}');
      print('Verification snapshot exists: ${snapshot.exists}');
      print('Verification completed');

      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
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
}
