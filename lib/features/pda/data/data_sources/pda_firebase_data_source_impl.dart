import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:hushh_user_app/shared/constants/firestore_constants.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';

class PdaFirebaseDataSourceImpl implements PdaDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Gemini API key
  static const String _geminiApiKey = 'AIzaSyD192xVzwNr_C4pwgGHenWpuPVOIH5Pa4w';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Helper method to check authentication state
  String? _getCurrentUserId() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      debugPrint(
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
      debugPrint('❌ [PDA FIREBASE] Error getting messages: $e');
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
      debugPrint('❌ [PDA FIREBASE] Error saving message: $e');
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
      debugPrint('❌ [PDA FIREBASE] Error deleting message: $e');
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
      debugPrint('❌ [PDA FIREBASE] Error clearing messages: $e');
      throw Exception('Failed to clear messages: $e');
    }
  }

  @override
  Future<String> sendToVertexAI(
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
You are Hush, a personal digital assistant for the Hushh app - a platform that connects users with agents who sell products and services. You help users navigate the app, understand features, and get the most out of their Hushh experience.

User Context:
${_formatUserContext(userContext)}

Conversation History:
${_formatConversationHistory(context)}

Current Message: $message

Please provide helpful responses related to:
- Hushh app features and navigation
- Product discovery and shopping
- Agent interactions and profiles
- Account management and settings
- App troubleshooting and support
- General questions about the Hushh platform

Keep responses relevant to the Hushh app ecosystem and user experience. If the user asks about unrelated topics, politely redirect them to Hushh-related assistance.
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
      debugPrint('❌ [PDA FIREBASE] Error sending to Gemini: $e');
      throw Exception('Failed to get response from AI: $e');
    }
  }

  @override
  Future<void> prewarmUserContext(String hushhId) async {
    debugPrint(
      '🚀 [PDA PREWARM] Starting PDA context prewarming for user: $hushhId',
    );
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('Warning: User not authenticated when prewarming context');
        return;
      }

      // Call Cloud Function to prewarm PDA with email context
      debugPrint('🧠 [PDA PREWARM] Calling prewarmPDA Cloud Function...');
      final callable = _functions.httpsCallable('prewarmPDA');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        if (data['hasGmailData'] == true) {
          debugPrint('✅ [PDA PREWARM] PDA prewarmed with email context');
          debugPrint(
            '📧 [PDA PREWARM] Email stats: ${data['context']?['emailStats']}',
          );
        } else {
          debugPrint(
            'ℹ️ [PDA PREWARM] PDA prewarmed without email data (Gmail not connected)',
          );
        }
      } else {
        debugPrint('⚠️ [PDA PREWARM] PDA prewarming completed with warnings');
      }

      // Also get local user context
      await getUserContext(currentUserId);
      debugPrint(
        '🚀 [PDA PREWARM] ✅ PDA context prewarming completed successfully',
      );
    } catch (e) {
      debugPrint('🚀 [PDA PREWARM] ⚠️ PDA context prewarming failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserContext(String hushhId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('Warning: User not authenticated when getting user context');
        return {};
      }

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) {
        debugPrint('⚠️ [PDA FIREBASE] User document not found');
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

      // Get email context from PDA context collection
      Map<String, dynamic> emailContext = {};
      try {
        final pdaContextDoc = await _firestore
            .collection('pdaContext')
            .doc(currentUserId)
            .get();

        if (pdaContextDoc.exists) {
          final pdaData = pdaContextDoc.data() as Map<String, dynamic>;
          emailContext = pdaData['emailContext'] ?? {};
          debugPrint(
            '📧 [PDA CONTEXT] Email context loaded: ${emailContext['emailStats']?['totalMessages'] ?? 0} messages',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [PDA CONTEXT] Could not load email context: $e');
      }

      return {
        'user_profile': userData,
        'recent_messages': recentMessages,
        'email_context': emailContext,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ [PDA FIREBASE] Error getting user context: $e');
      return {};
    }
  }

  String _formatUserContext(Map<String, dynamic> context) {
    if (context.isEmpty) return 'No user context available.';

    final userProfile = context['user_profile'] as Map<String, dynamic>?;
    if (userProfile == null) return 'No user profile available.';

    final emailContext = context['email_context'] as Map<String, dynamic>?;

    String emailInfo = '';
    if (emailContext != null && emailContext.isNotEmpty) {
      final emailStats = emailContext['emailStats'] as Map<String, dynamic>?;
      final emailInsights = emailContext['emailInsights'] as List<dynamic>?;

      if (emailStats != null) {
        emailInfo =
            '''
Email Data:
- Total Threads: ${emailStats['totalThreads'] ?? 0}
- Total Messages: ${emailStats['totalMessages'] ?? 0}
- Recent Threads: ${emailStats['recentThreads'] ?? 0}
- Recent Messages: ${emailStats['recentMessages'] ?? 0}
''';
      }

      if (emailInsights != null && emailInsights.isNotEmpty) {
        emailInfo += '\nEmail Insights:\n';
        for (final insight in emailInsights.take(3)) {
          emailInfo += '- ${insight['message']}\n';
        }
      }
    }

    return '''
Name: ${userProfile['name'] ?? 'Not provided'}
Email: ${userProfile['email'] ?? 'Not provided'}
Created: ${userProfile['createdAt'] ?? 'Not provided'}
Last Updated: ${userProfile['updatedAt'] ?? 'Not provided'}

$emailInfo
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
