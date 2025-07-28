import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:hushh_user_app/shared/constants/firestore_constants.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';

class PdaFirebaseDataSourceImpl implements PdaDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gemini API key
  static const String _geminiApiKey = 'AIzaSyD192xVzwNr_C4pwgGHenWpuPVOIH5Pa4w';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Helper method to check authentication state
  String? _getCurrentUserId() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print(
        '⚠️ [PDA AUTH] User not authenticated. Please sign in to use PDA features.',
      );
    }
    return currentUserId;
  }

  @override
  Future<List<PdaMessageModel>> getMessages(String userId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => PdaMessageModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('❌ [PDA FIREBASE] Error getting messages: $e');
      throw Exception('Failed to get messages: $e');
    }
  }

  @override
  Future<void> saveMessage(PdaMessageModel message) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      print('❌ [PDA FIREBASE] Error saving message: $e');
      throw Exception('Failed to save message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('❌ [PDA FIREBASE] Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<void> clearMessages(String userId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('❌ [PDA FIREBASE] Error clearing messages: $e');
      throw Exception('Failed to clear messages: $e');
    }
  }

  @override
  Future<String> sendToGemini(
    String message,
    List<PdaMessageModel> context,
  ) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get user context from Firebase
      final userContext = await getUserContext(currentUserId);

      // Prepare conversation history (not used in current implementation but kept for future use)
      // final conversationHistory = context
      //     .take(10) // Limit to last 10 messages for context
      //     .map(
      //       (msg) => {
      //         'role': msg.isFromUser ? 'user' : 'assistant',
      //         'parts': [
      //           {'text': msg.content},
      //         ],
      //       },
      //     )
      //     .toList();

      // Prepare the request body
      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    '''
You are Hush, a personal digital assistant. You have access to the user's context and conversation history.

User Context:
${_formatUserContext(userContext)}

Conversation History:
${_formatConversationHistory(context)}

Current Message: $message

Please provide a helpful, contextual response based on the user's context and conversation history.
''',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final candidates = responseData['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts.first['text'] as String;
          }
        }
        throw Exception('Invalid response format from Gemini API');
      } else {
        throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [PDA FIREBASE] Error sending to Gemini: $e');
      throw Exception('Failed to get response from AI: $e');
    }
  }

  @override
  Future<void> prewarmUserContext(String hushhId) async {
    print(
      '🚀 [PDA PREWARM] Starting PDA context prewarming for user: $hushhId',
    );
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        print('Warning: User not authenticated when prewarming context');
        return;
      }

      await getUserContext(currentUserId);
      print('🚀 [PDA PREWARM] ✅ PDA context prewarming completed successfully');
    } catch (e) {
      print('🚀 [PDA PREWARM] ⚠️ PDA context prewarming failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserContext(String hushhId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        print('Warning: User not authenticated when getting user context');
        return {};
      }

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) {
        print('⚠️ [PDA FIREBASE] User document not found');
        return {};
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get recent PDA messages for context
      final messagesQuery = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final recentMessages = messagesQuery.docs
          .map((doc) => doc.data())
          .toList();

      return {
        'user_profile': userData,
        'recent_messages': recentMessages,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [PDA FIREBASE] Error getting user context: $e');
      return {};
    }
  }

  String _formatUserContext(Map<String, dynamic> context) {
    if (context.isEmpty) return 'No user context available.';

    final userProfile = context['user_profile'] as Map<String, dynamic>?;
    if (userProfile == null) return 'No user profile available.';

    return '''
Name: ${userProfile['name'] ?? 'Not provided'}
Email: ${userProfile['email'] ?? 'Not provided'}
Created: ${userProfile['createdAt'] ?? 'Not provided'}
Last Updated: ${userProfile['updatedAt'] ?? 'Not provided'}
''';
  }

  String _formatConversationHistory(List<PdaMessageModel> context) {
    if (context.isEmpty) return 'No conversation history.';

    return context
        .take(5) // Limit to last 5 messages for brevity
        .map(
          (msg) => '${msg.isFromUser ? 'User' : 'Assistant'}: ${msg.content}',
        )
        .join('\n');
  }
}
