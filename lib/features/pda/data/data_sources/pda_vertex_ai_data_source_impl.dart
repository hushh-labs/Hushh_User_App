import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http; // Not needed - using googleapis_auth client
import 'package:googleapis_auth/auth_io.dart';
import 'package:hushh_user_app/shared/constants/firestore_constants.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';
import 'package:hushh_user_app/features/pda/data/config/vertex_ai_config.dart';
import 'package:hushh_user_app/shared/services/gmail_connector_service.dart';

class PdaVertexAiDataSourceImpl implements PdaDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GmailConnectorService _gmailService = GmailConnectorService();
  
  // Stream subscription for email events
  StreamSubscription<EmailEvent>? _emailEventSubscription;
  List<String> _cachedEmailSummaries = [];
  bool _isMonitoringEmails = false;

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

  // Get authenticated HTTP client for Vertex AI
  Future<AuthClient> _getAuthenticatedClient() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      jsonDecode(VertexAiConfig.serviceAccountKey),
    );

    return clientViaServiceAccount(
      serviceAccountCredentials,
      VertexAiConfig.scopes,
    );
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
          .limit(VertexAiConfig.maxStoredMessages)
          .get();

      return querySnapshot.docs
          .map((doc) => PdaMessageModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      debugPrint('❌ [PDA VERTEX AI] Error getting messages: $e');
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
      debugPrint('❌ [PDA VERTEX AI] Error saving message: $e');
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
      debugPrint('❌ [PDA VERTEX AI] Error deleting message: $e');
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

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ [PDA VERTEX AI] Error clearing messages: $e');
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

      // Validate Vertex AI configuration
      if (!VertexAiConfig.isConfigured) {
        throw Exception(
          'Vertex AI is not properly configured. Please check your .env file and ensure VERTEX_AI_PROJECT_ID and VERTEX_AI_SERVICE_ACCOUNT_KEY are set.',
        );
      }

      // Get user context from Firebase
      final userContext = await getUserContext(currentUserId);

      // Get email summaries for enhanced context (if Gmail is connected)
      final emailSummaries = await _getEmailSummariesForContext();

      // Get authenticated client
      final client = await _getAuthenticatedClient();

      // Prepare the request URL for Vertex AI Claude
      final url =
          'https://${VertexAiConfig.location}-aiplatform.googleapis.com/v1/projects/${VertexAiConfig.projectId}/locations/${VertexAiConfig.location}/publishers/anthropic/models/${VertexAiConfig.model}:streamRawPredict';

      // Prepare conversation history for Claude
      final conversationHistory = _formatConversationForClaude(context);

      // Prepare enhanced context with email summaries
      final emailContext = emailSummaries.isNotEmpty 
          ? '\n\nRecent Email Activity:\n${emailSummaries.join('\n')}'
          : '';

      // Prepare the request body for Claude via Vertex AI streamRawPredict endpoint
      final requestBody = {
        'anthropic_version': VertexAiConfig.anthropicVersion,
        'messages': [
          {
            'role': 'user',
            'content':
                '''
You are Hush, a personal digital assistant for the Hushh app - a platform that connects users with agents who sell products and services. You help users navigate the app, understand features, and get the most out of their Hushh experience.

User Context:
${_formatUserContext(userContext)}$emailContext

Conversation History:
$conversationHistory

Current Message: $message

Please provide helpful responses related to:
- Hushh app features and navigation
- Product discovery and shopping
- Agent interactions and profiles
- Account management and settings
- App troubleshooting and support
- General questions about the Hushh platform
- Email-related insights (if email data is available)

When email context is available, you can reference relevant emails to provide more personalized assistance. For example, if the user mentions a product or order, you can check if there are related emails and provide insights.

Keep responses relevant to the Hushh app ecosystem and user experience. If the user asks about unrelated topics, politely redirect them to Hushh-related assistance.

Be conversational, helpful, and concise in your responses.
''',
          },
        ],
        'max_tokens': VertexAiConfig.maxTokens,
        'temperature': VertexAiConfig.temperature,
        'top_p': VertexAiConfig.topP,
        'top_k': VertexAiConfig.topK,
      };

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Close the authenticated client
      client.close();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Parse Claude streamRawPredict response format
        if (responseData['content'] != null &&
            responseData['content'] is List &&
            (responseData['content'] as List).isNotEmpty) {
          final content = responseData['content'][0];
          if (content['text'] != null) {
            return content['text'] as String;
          }
        }

        throw Exception('Invalid response format from Vertex AI API');
      } else {
        throw Exception(
          'Vertex AI Claude API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [PDA VERTEX AI] Error sending to Claude: $e');
      throw Exception('Failed to get response from AI: $e');
    }
  }

  @override
  Future<void> prewarmUserContext(String hushhId) async {
    debugPrint(
      '🚀 [PDA PREWARM] Starting PDA context prewarming for user: \$hushhId',
    );
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('Warning: User not authenticated when prewarming context');
        return;
      }

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
        debugPrint('⚠️ [PDA VERTEX AI] User document not found');
        return {};
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get recent PDA messages for context
      final messagesQuery = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection('pda_messages')
          .orderBy('timestamp', descending: true)
          .limit(VertexAiConfig.maxRecentMessages)
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
      debugPrint('❌ [PDA VERTEX AI] Error getting user context: $e');
      return {};
    }
  }

  String _formatUserContext(Map<String, dynamic> context) {
    if (context.isEmpty) return 'No user context available.';

    final userProfile = context['user_profile'] as Map<String, dynamic>?;
    if (userProfile == null) return 'No user profile available.';

    final name =
        (userProfile['name'] ?? userProfile['fullName']) ?? 'Not provided';
    final email = userProfile['email'] ?? 'Not provided';
    final createdAt = userProfile['createdAt'] ?? 'Not provided';
    final updatedAt =
        (userProfile['updatedAt'] ?? userProfile['updated_at']) ??
        'Not provided';
    final phoneNumber = userProfile['phoneNumber'] ?? 'Not provided';
    final isActive = userProfile['isActive'];
    final isPhoneVerified = userProfile['isPhoneVerified'];
    final platform = userProfile['platform'] ?? 'Not provided';
    final userId =
        (userProfile['userId'] ?? userProfile['id']) ?? 'Not provided';

    return '''
Name: $name
Email: $email
Phone: $phoneNumber
User ID: $userId
Platform: $platform
Active: ${isActive is bool ? (isActive ? 'true' : 'false') : (isActive?.toString() ?? 'Not provided')}
Phone Verified: ${isPhoneVerified is bool ? (isPhoneVerified ? 'true' : 'false') : (isPhoneVerified?.toString() ?? 'Not provided')}
Account Created: $createdAt
Last Updated: $updatedAt
''';
  }

  String _formatConversationForClaude(List<PdaMessageModel> context) {
    if (context.isEmpty) return 'No conversation history.';

    return context
        .take(
          VertexAiConfig.maxConversationHistory,
        ) // Limit to last messages for brevity
        .map(
          (msg) => '${msg.isFromUser ? 'User' : 'Assistant'}: ${msg.content}',
        )
        .join('\n');
  }

  /// Get email summaries for PDA context enhancement
  Future<List<String>> _getEmailSummariesForContext() async {
    try {
      // Use cached summaries if available and monitoring is active
      if (_isMonitoringEmails && _cachedEmailSummaries.isNotEmpty) {
        debugPrint('📧 [PDA EMAIL CONTEXT] Using cached email summaries');
        return _cachedEmailSummaries;
      }
      
      // Check if Gmail is connected
      final isConnected = await _gmailService.isGmailConnected();
      if (!isConnected) {
        debugPrint('📧 [PDA EMAIL CONTEXT] Gmail not connected, skipping email context');
        return [];
      }

      debugPrint('📧 [PDA EMAIL CONTEXT] Fetching email summaries for PDA context...');
      
      // Get recent email summaries (limit to 10 for context)
      final emailSummaries = await _gmailService.getRecentEmailSummaries(limit: 10);
      
      // Cache the summaries
      _cachedEmailSummaries = emailSummaries;
      
      if (emailSummaries.isNotEmpty) {
        debugPrint('📧 [PDA EMAIL CONTEXT] Found ${emailSummaries.length} email summaries');
      }
      
      return emailSummaries;
    } catch (e) {
      debugPrint('❌ [PDA EMAIL CONTEXT] Error getting email summaries: $e');
      return [];
    }
  }

  /// Start monitoring emails for real-time PDA context updates
  Future<void> startEmailMonitoring() async {
    if (_isMonitoringEmails) return;

    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return;

      final isConnected = await _gmailService.isGmailConnected();
      if (!isConnected) {
        debugPrint('📧 [PDA EMAIL MONITOR] Gmail not connected, skipping email monitoring');
        return;
      }

      debugPrint('📧 [PDA EMAIL MONITOR] Starting email monitoring for PDA...');

      // Start Gmail service monitoring
      await _gmailService.startEmailMonitoring();

      // Listen to email events
      _emailEventSubscription = _gmailService.emailEventsStream.listen((event) {
        _handleEmailEvent(event);
      });

      _isMonitoringEmails = true;
      debugPrint('📧 [PDA EMAIL MONITOR] Email monitoring started successfully');
    } catch (e) {
      debugPrint('❌ [PDA EMAIL MONITOR] Error starting email monitoring: $e');
    }
  }

  /// Stop email monitoring
  void stopEmailMonitoring() {
    if (!_isMonitoringEmails) return;

    debugPrint('📧 [PDA EMAIL MONITOR] Stopping email monitoring...');

    _emailEventSubscription?.cancel();
    _emailEventSubscription = null;
    _gmailService.stopEmailMonitoring();
    _isMonitoringEmails = false;
    _cachedEmailSummaries.clear();

    debugPrint('📧 [PDA EMAIL MONITOR] Email monitoring stopped');
  }

  /// Handle email events from Gmail service
  void _handleEmailEvent(EmailEvent event) {
    debugPrint('📧 [PDA EMAIL MONITOR] Received email event: ${event.type}');

    switch (event.type) {
      case EmailEventType.newEmails:
        _handleNewEmails(event.threads);
        break;
      case EmailEventType.contextRefresh:
        _refreshEmailContext();
        break;
    }
  }

  /// Handle new emails by updating cached summaries
  void _handleNewEmails(List<EmailThreadSummary> newThreads) {
    if (newThreads.isEmpty) return;

    debugPrint('📧 [PDA EMAIL MONITOR] Processing ${newThreads.length} new email threads');

    // Update cached summaries with new emails
    final newSummaries = newThreads.map((thread) => thread.formattedSummary).toList();
    
    // Add new summaries to the beginning of the cache and limit to 10
    _cachedEmailSummaries = [...newSummaries, ..._cachedEmailSummaries].take(10).toList();

    debugPrint('📧 [PDA EMAIL MONITOR] Updated PDA email context with ${newSummaries.length} new emails');
  }

  /// Refresh email context by re-fetching summaries
  Future<void> _refreshEmailContext() async {
    debugPrint('📧 [PDA EMAIL MONITOR] Refreshing email context...');
    
    try {
      final freshSummaries = await _gmailService.getRecentEmailSummaries(limit: 10);
      _cachedEmailSummaries = freshSummaries;
      debugPrint('📧 [PDA EMAIL MONITOR] Email context refreshed with ${freshSummaries.length} summaries');
    } catch (e) {
      debugPrint('❌ [PDA EMAIL MONITOR] Error refreshing email context: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopEmailMonitoring();
  }
}
