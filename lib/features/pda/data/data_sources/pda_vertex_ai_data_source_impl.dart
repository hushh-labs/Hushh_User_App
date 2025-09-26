import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http; // Not needed - using googleapis_auth client
import 'package:googleapis_auth/auth_io.dart';
import 'package:hushh_user_app/shared/constants/firestore_constants.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_response.dart';
import 'package:hushh_user_app/features/pda/data/config/vertex_ai_config.dart';
import 'package:hushh_user_app/shared/services/gmail_connector_service.dart';
import 'package:get_it/get_it.dart';
import '../services/linkedin_context_prewarm_service.dart';
import '../services/gmail_context_prewarm_service.dart';
import '../services/google_calendar_context_prewarm_service.dart';
import '../services/google_meet_context_prewarm_service.dart';
import '../../domain/repositories/gmail_repository.dart';
import '../../domain/repositories/google_meet_repository.dart';
import '../services/prewarming_coordinator_service.dart';
import '../services/gemini_file_processor_service.dart';
import 'package:hushh_user_app/features/vault/data/services/supabase_document_context_prewarm_service.dart';
import 'package:hushh_user_app/features/vault/data/services/vault_startup_prewarm_service.dart';
import 'package:hushh_user_app/features/vault/data/services/local_file_cache_service.dart';
import '../services/api_cost_logger.dart';

class PdaVertexAiDataSourceImpl implements PdaDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GmailConnectorService _gmailService = GmailConnectorService();
  final LinkedInContextPrewarmService _linkedInPrewarmService =
      LinkedInContextPrewarmService();
  final GmailContextPrewarmService _gmailPrewarmService =
      GmailContextPrewarmService();
  GoogleCalendarContextPrewarmService? _googleCalendarPrewarmService;
  final GoogleMeetContextPrewarmService _googleMeetPrewarmService =
      GoogleMeetContextPrewarmService();
  final SupabaseDocumentContextPrewarmService _documentPrewarmService =
      SupabaseDocumentContextPrewarmServiceImpl();
  VaultStartupPrewarmService? _vaultPrewarmService;
  final PrewarmingCoordinatorService _prewarmingCoordinator =
      PrewarmingCoordinatorService();

  // Constructor to initialize GetIt dependencies
  PdaVertexAiDataSourceImpl() {
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _googleCalendarPrewarmService =
          GetIt.instance<GoogleCalendarContextPrewarmService>();
      debugPrint('✅ [PDA VERTEX AI] Google Calendar service initialized');
    } catch (e) {
      debugPrint(
        '⚠️ [PDA VERTEX AI] Failed to initialize Google Calendar service: $e',
      );
      // Skip initialization if GetIt service is not available
      // This will cause the service to be null, which we'll handle in usage
    }

    try {
      _vaultPrewarmService = GetIt.instance<VaultStartupPrewarmService>();
      debugPrint('✅ [PDA VERTEX AI] Vault service initialized');
    } catch (e) {
      debugPrint('⚠️ [PDA VERTEX AI] Failed to initialize Vault service: $e');
      // Skip initialization if GetIt service is not available
      // This will cause the service to be null, which we'll handle in usage
    }
  }

  final LocalFileCacheService _cacheService = LocalFileCacheService();
  final GeminiFileProcessorService _geminiProcessor =
      GeminiFileProcessorService();

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
  Future<PdaResponse> sendToVertexAI(
    String message,
    List<PdaMessageModel> context, {
    List<File>? imageFiles,
  }) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Validate Vertex AI configuration
      if (!VertexAiConfig.isConfigured) {
        throw Exception(
          'Vertex AI is not properly configured. Please check your Firebase Remote Config and ensure vertex_ai_project_id and vertex_ai_service_account_key are set.',
        );
      }

      // Get user context from Firebase
      final userContext = await getUserContext(currentUserId);

      // Get Gmail context from Supabase for enhanced responses (if Gmail is connected)
      final gmailContext = await _getGmailContextForPda();

      // Get LinkedIn context for enhanced responses (if LinkedIn is connected)
      final linkedInContext = await _getLinkedInContextForPda();

      // Get Google Calendar context for enhanced responses (if Calendar is connected)
      final calendarContext = await _getGoogleCalendarContextForPda();

      final documentContext = await _getDocumentContextForPda();

      // Get authenticated client
      final client = await _getAuthenticatedClient();

      // Prepare the request URL for Vertex AI Claude
      final url =
          'https://${VertexAiConfig.location}-aiplatform.googleapis.com/v1/projects/${VertexAiConfig.projectId}/locations/${VertexAiConfig.location}/publishers/anthropic/models/${VertexAiConfig.model}:streamRawPredict';

      // Prepare conversation history for Claude
      final conversationHistory = _formatConversationForClaude(context);

      // Prepare Gmail context
      final gmailContextText = gmailContext.isNotEmpty
          ? '\n\nGmail Context:\n$gmailContext'
          : '';

      // Prepare LinkedIn context
      final linkedInContextText = linkedInContext.isNotEmpty
          ? '\n\nLinkedIn Professional Context:\n$linkedInContext'
          : '';

      // Prepare Google Calendar context
      final calendarContextText = calendarContext.isNotEmpty
          ? '\n\nGoogle Calendar Context:\n$calendarContext'
          : '';

      // Prepare Document context
      final documentContextText = documentContext.isNotEmpty
          ? '\n\nUser Document Context:\n$documentContext'
          : '';

      // Get document files for multimodal input
      final documentResult = await _getDocumentFilesForClaude();
      final documentFiles = (documentResult['files'] as List)
          .cast<Map<String, dynamic>>();
      final vaultGeminiCost = documentResult['geminiCost'] as double;

      // Handle user-uploaded images
      debugPrint(
        '🔍 [VERTEX AI] Image files received: ${imageFiles?.length ?? 0}',
      );
      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint(
          '🔍 [VERTEX AI] Processing ${imageFiles.length} user images...',
        );
        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          try {
            debugPrint(
              '🔍 [VERTEX AI] Processing image ${i + 1}/${imageFiles.length}: ${imageFile.path}',
            );
            final imageBytes = await imageFile.readAsBytes();
            final base64Image = base64Encode(imageBytes);
            final mimeType = _getMimeTypeFromFile(imageFile);

            documentFiles.add({
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mimeType,
                'data': base64Image,
              },
            });

            debugPrint(
              '📸 [VERTEX AI] ✅ Successfully added user image ${i + 1} to multimodal input: ${imageFile.path} (${imageBytes.length} bytes, $mimeType)',
            );
          } catch (e) {
            debugPrint(
              '❌ [VERTEX AI] Error processing user image ${i + 1}: $e',
            );
          }
        }
        debugPrint(
          '🔍 [VERTEX AI] Total document files after adding user images: ${documentFiles.length}',
        );
      } else {
        debugPrint('⚠️ [VERTEX AI] No user images provided or empty list');
      }

      // Build the main prompt text
      final mainPromptText =
          '''
You are Hush, a personal digital assistant for the Hushh app - a platform that connects users with agents who sell products and services. You help users navigate the app, understand features, and get the most out of their Hushh experience.

CRITICAL INSTRUCTION: Your responses MUST be professional and MUST NOT contain any emojis. If you generate any emojis, you MUST remove them before outputting the response. Use clear, concise language that maintains a professional tone throughout the conversation.

User Context:
${_formatUserContext(userContext)}$gmailContextText$linkedInContextText$calendarContextText$documentContextText

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
- Gmail-related insights and email management (if Gmail data is available)
- LinkedIn professional networking and career insights (if LinkedIn data is available)
- Google Calendar scheduling and meeting management (if Calendar data is available)
- Document-related insights and information retrieval (if user documents are available)

When Gmail context is available, you can reference relevant emails to provide more personalized assistance. For example, if the user mentions a product or order, you can check if there are related emails and provide insights. You can also help with email management, unread emails, and important messages.

When LinkedIn context is available, you can provide professional networking insights, career guidance, and help with professional connections and opportunities.

When Google Calendar context is available, you can help with scheduling, meeting management, and calendar-related queries. For example, you can answer questions like "Do I have a meeting tomorrow?", "What's my next meeting?", "When is my meeting with [person]?", provide meeting details including Google Meet links, help identify scheduling conflicts, and remind about upcoming meetings. You can also correlate calendar events with Google Meet data to provide comprehensive meeting context.

When Document context is available, you can reference relevant documents to provide more personalized assistance. For example, if the user asks about a topic, you can check if there are related documents and provide insights or summaries from them.

Keep responses relevant to the Hushh app ecosystem and user experience. If the user asks about unrelated topics, politely redirect them to Hushh-related assistance.

Be conversational, helpful, and concise in your responses.
''';

      // Log comprehensive input details
      debugPrint(
        '🔍 [VERTEX AI INPUT] ===== COMPREHENSIVE INPUT LOGGING =====',
      );
      debugPrint('🔍 [VERTEX AI INPUT] User Message: $message');
      debugPrint(
        '🔍 [VERTEX AI INPUT] User Context Length: ${_formatUserContext(userContext).length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Gmail Context Length: ${gmailContext.length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] LinkedIn Context Length: ${linkedInContext.length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Calendar Context Length: ${calendarContext.length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Document Context Length: ${documentContext.length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Conversation History Length: ${conversationHistory.length} characters',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Document Files Count: ${documentFiles.length}',
      );
      debugPrint(
        '🔍 [VERTEX AI INPUT] Main Prompt Length: ${mainPromptText.length} characters',
      );

      // Log the actual calendar context being sent
      if (calendarContext.isNotEmpty) {
        debugPrint(
          '🔍 [VERTEX AI CALENDAR] ===== CALENDAR CONTEXT BEING SENT =====',
        );
        debugPrint('🔍 [VERTEX AI CALENDAR] $calendarContext');
        debugPrint('🔍 [VERTEX AI CALENDAR] ===== END CALENDAR CONTEXT =====');
      } else {
        debugPrint('🔍 [VERTEX AI CALENDAR] ⚠️ NO CALENDAR CONTEXT AVAILABLE');
      }

      // Prepare content with text and files
      final List<Map<String, dynamic>> contentParts = [
        {'type': 'text', 'text': mainPromptText},
      ];

      // Add document files to content
      contentParts.addAll(documentFiles);

      // Prepare the request body for Claude via Vertex AI streamRawPredict endpoint
      final requestBody = {
        'anthropic_version': VertexAiConfig.anthropicVersion,
        'messages': [
          {'role': 'user', 'content': contentParts},
        ],
        'max_tokens': VertexAiConfig.maxTokens,
        'temperature': VertexAiConfig.temperature,
        'top_p': VertexAiConfig.topP,
        'top_k': VertexAiConfig.topK,
      };

      // Log the complete request body structure (without sensitive data)
      debugPrint('🔍 [VERTEX AI REQUEST] ===== REQUEST STRUCTURE =====');
      debugPrint(
        '🔍 [VERTEX AI REQUEST] Anthropic Version: ${requestBody['anthropic_version']}',
      );
      debugPrint(
        '🔍 [VERTEX AI REQUEST] Max Tokens: ${requestBody['max_tokens']}',
      );
      debugPrint(
        '🔍 [VERTEX AI REQUEST] Temperature: ${requestBody['temperature']}',
      );
      debugPrint('🔍 [VERTEX AI REQUEST] Top P: ${requestBody['top_p']}');
      debugPrint('🔍 [VERTEX AI REQUEST] Top K: ${requestBody['top_k']}');
      debugPrint(
        '🔍 [VERTEX AI REQUEST] Content Parts Count: ${contentParts.length}',
      );
      debugPrint(
        '🔍 [VERTEX AI REQUEST] Total Request Body Size: ${jsonEncode(requestBody).length} characters',
      );
      debugPrint('🔍 [VERTEX AI REQUEST] ===== END REQUEST STRUCTURE =====');

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
            final responseText = content['text'] as String;

            // Calculate cost for this API call
            final inputTokens = ApiCostLogger.estimateTokensFromText(
              mainPromptText,
            );
            final outputTokens = ApiCostLogger.estimateTokensFromText(
              responseText,
            );

            // Add tokens for document files
            int documentTokens = 0;
            for (final file in documentFiles) {
              if (file['type'] == 'image' && file['source'] != null) {
                final source = file['source'] as Map<String, dynamic>;
                final base64Data = source['data'] as String? ?? '';
                final mimeType = source['media_type'] as String? ?? '';
                documentTokens += ApiCostLogger.estimateTokensFromBase64(
                  base64Data,
                  mimeType,
                );
              }
            }

            final totalInputTokens = inputTokens + documentTokens;
            final claudeCost = ApiCostLogger.calculateVertexAiCost(
              inputTokens: totalInputTokens,
              outputTokens: outputTokens,
            );

            // Get Gemini preprocessing cost for vault documents
            final totalCost = claudeCost + vaultGeminiCost;

            // Log cost information for this API call
            debugPrint(
              '💰 [COST BREAKDOWN] Claude 3.5 Sonnet: \$${claudeCost.toStringAsFixed(6)}',
            );
            if (vaultGeminiCost > 0) {
              debugPrint(
                '💰 [COST BREAKDOWN] Gemini 1.5 Pro (vault preprocessing): \$${vaultGeminiCost.toStringAsFixed(6)}',
              );
            }
            debugPrint(
              '💰 [COST BREAKDOWN] TOTAL COST: \$${totalCost.toStringAsFixed(6)}',
            );

            ApiCostLogger.logVertexAiCost(
              prompt: mainPromptText,
              response: responseText,
              documentFiles: documentFiles,
            );

            return PdaResponse(content: responseText, cost: totalCost);
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
    const prewarmProcessName = 'pda_vertex_ai_prewarm';

    // Use coordinator to prevent duplicate prewarming
    await _prewarmingCoordinator.startProcess(prewarmProcessName, () async {
      debugPrint(
        '🚀 [PDA PREWARM] Starting PDA context prewarming for user: \$hushhId',
      );
      try {
        final currentUserId = _getCurrentUserId();
        if (currentUserId == null) {
          debugPrint('Warning: User not authenticated when prewarming context');
          return;
        }

        // Pre-warm user context
        await getUserContext(currentUserId);

        // Pre-warm all services in parallel using coordinator
        // This handles all prewarming to eliminate duplicates
        final futures = <Future<void>>[
          _prewarmingCoordinator.startProcess(
            'gmail_prewarm',
            () => _gmailPrewarmService.prewarmGmailContext(),
          ),
          _prewarmingCoordinator.startProcess(
            'linkedin_prewarm',
            () => _linkedInPrewarmService.prewarmLinkedInContext(),
          ),
          _prewarmingCoordinator.startProcess(
            'google_calendar_prewarm',
            () => _googleCalendarPrewarmService?.prewarmOnStartup(currentUserId) ?? Future.value(),
          ),
          _prewarmingCoordinator.startProcess(
            'document_prewarm',
            () => _documentPrewarmService.getPrewarmedContext(
              userId: currentUserId,
            ),
          ),
          _prewarmingCoordinator.startProcess(
            'google_meet_prewarm',
            () => _googleMeetPrewarmService.prewarmGoogleMeetContext(),
          ),
          _prewarmingCoordinator.startProcess(
            'vault_prewarm',
            () => _vaultPrewarmService?.prewarmVaultOnStartup() ?? Future.value(),
          ),
        ];

        // Wait for all to complete
        await Future.wait(futures);

        debugPrint(
          '🚀 [PDA PREWARM] ✅ PDA context prewarming completed successfully',
        );
      } catch (e) {
        debugPrint('🚀 [PDA PREWARM] ⚠️ PDA context prewarming failed: $e');
        rethrow;
      }
    });
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

  /// Get Gmail context for PDA responses
  Future<String> _getGmailContextForPda() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return '';

      // Check if Gmail is still connected before providing context
      final gmailRepo = GetIt.instance<GmailRepository>();
      final isGmailConnected = await gmailRepo.isGmailConnected(currentUserId);
      if (!isGmailConnected) {
        debugPrint(
          '🚫 [PDA GMAIL CONTEXT] Gmail disconnected - blocking context access',
        );
        return '';
      }

      // First try to get from local cache (fastest)
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString('gmail_pda_context_$currentUserId');

      if (contextJson != null && contextJson.isNotEmpty) {
        try {
          final context = jsonDecode(contextJson) as Map<String, dynamic>;
          final summary = context['summary'] as String?;
          final recentEmails = context['recentEmails'] as List<dynamic>? ?? [];

          if (summary != null && summary.isNotEmpty) {
            debugPrint(
              '📦 [PDA GMAIL CONTEXT] Using local cached Gmail context',
            );

            // Include both summary and detailed email data
            final detailedContext = StringBuffer();
            detailedContext.writeln(summary);

            // Add detailed email data for better AI responses
            if (recentEmails.isNotEmpty) {
              detailedContext.writeln('\n=== DETAILED EMAIL DATA ===');
              detailedContext.writeln('ALL Emails (Complete Full Data):');
              // Show ALL emails - no limits
              for (int i = 0; i < recentEmails.length; i++) {
                final email = recentEmails[i] as Map<String, dynamic>;
                detailedContext.writeln('\n--- Email ${i + 1} ---');
                detailedContext.writeln(
                  'From: ${email['fromName'] ?? email['fromEmail'] ?? 'Unknown'}',
                );
                detailedContext.writeln(
                  'Subject: ${email['subject'] ?? 'No Subject'}',
                );
                detailedContext.writeln('Date: ${email['receivedAt']}');
                detailedContext.writeln('Read: ${email['isRead']}');
                detailedContext.writeln('Important: ${email['isImportant']}');

                if (email['bodyText'] != null &&
                    email['bodyText'].toString().isNotEmpty) {
                  final bodyText = email['bodyText'].toString();
                  final bodyPreview = bodyText.length > 300
                      ? '${bodyText.substring(0, 300)}...'
                      : bodyText;
                  detailedContext.writeln('Content: $bodyPreview');
                } else if (email['snippet'] != null &&
                    email['snippet'].toString().isNotEmpty) {
                  detailedContext.writeln('Snippet: ${email['snippet']}');
                }
              }
            }

            return detailedContext.toString();
          }
        } catch (e) {
          debugPrint('❌ [PDA GMAIL CONTEXT] Error parsing local cache: $e');
        }
      }

      // Fallback to prewarm service if no local cache
      debugPrint('📦 [PDA GMAIL CONTEXT] No local cache, fetching fresh data');
      return await _gmailPrewarmService.getGmailContextForPda();
    } catch (e) {
      debugPrint('❌ [PDA GMAIL CONTEXT] Error getting Gmail context: $e');
      return '';
    }
  }

  /// Get LinkedIn context for PDA responses
  Future<String> _getLinkedInContextForPda() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return '';

      // First try to get from Firestore cache (fastest)
      final doc = await _firestore
          .collection('HushUsers')
          .doc(currentUserId)
          .collection('pda_context')
          .doc('linkedin')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final context = data['context'] as Map<String, dynamic>? ?? {};
        final summary = context['summary'] as String?;
        if (summary != null && summary.isNotEmpty) {
          debugPrint('📦 [PDA LINKEDIN CONTEXT] Using cached LinkedIn context');
          return summary;
        }
      }

      // Fallback to prewarm service if no cache
      debugPrint(
        '📦 [PDA LINKEDIN CONTEXT] No cached context, fetching fresh data',
      );
      return await _linkedInPrewarmService.getLinkedInContextForPda();
    } catch (e) {
      debugPrint('❌ [PDA LINKEDIN CONTEXT] Error getting LinkedIn context: $e');
      return '';
    }
  }

  /// Get Google Calendar context for PDA responses
  Future<String> _getGoogleCalendarContextForPda() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return '';

      // Check if Google Meet is still connected before providing calendar context
      final googleMeetRepo = GetIt.instance<GoogleMeetRepository>();
      final isGoogleMeetConnected = await googleMeetRepo.isGoogleMeetConnected(
        currentUserId,
      );
      if (!isGoogleMeetConnected) {
        debugPrint(
          '🚫 [PDA CALENDAR CONTEXT] Google Meet disconnected - blocking calendar context access',
        );
        return '';
      }

      debugPrint(
        '📦 [PDA CALENDAR CONTEXT] Getting fresh calendar context for PDA',
      );

      // Always get fresh data from prewarm service (bypass Firestore cache)
      final calendarContext = _googleCalendarPrewarmService != null
          ? await _googleCalendarPrewarmService!
              .getGoogleCalendarContextForPdaWithUserId(currentUserId)
          : null;

      debugPrint(
        '📦 [PDA CALENDAR CONTEXT] Calendar context length: ${calendarContext?.length ?? 0} characters',
      );

      return calendarContext ?? '';
    } catch (e) {
      debugPrint(
        '❌ [PDA CALENDAR CONTEXT] Error getting Google Calendar context: $e',
      );
      return '';
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
        debugPrint(
          '📧 [PDA EMAIL MONITOR] Gmail not connected, skipping email monitoring',
        );
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
      debugPrint(
        '📧 [PDA EMAIL MONITOR] Email monitoring started successfully',
      );

      // Also start Gmail and LinkedIn monitoring
      _gmailPrewarmService.startGmailMonitoring();
      _linkedInPrewarmService.startLinkedInMonitoring();
      debugPrint('📧 [PDA GMAIL MONITOR] Gmail monitoring started');
      debugPrint('🔗 [PDA LINKEDIN MONITOR] LinkedIn monitoring started');
      // Also start document monitoring if applicable (e.g., for real-time updates on document processing)
      // _documentPrewarmService.startDocumentMonitoring(); // If such a method exists
      debugPrint(
        '📄 [PDA DOCUMENT MONITOR] Document monitoring started (if applicable)',
      );
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

    debugPrint(
      '📧 [PDA EMAIL MONITOR] Processing ${newThreads.length} new email threads',
    );

    // Update cached summaries with new emails
    final newSummaries = newThreads
        .map((thread) => thread.formattedSummary)
        .toList();

    // Add new summaries to the beginning of the cache and limit to 10
    _cachedEmailSummaries = [
      ...newSummaries,
      ..._cachedEmailSummaries,
    ].take(10).toList();

    debugPrint(
      '📧 [PDA EMAIL MONITOR] Updated PDA email context with ${newSummaries.length} new emails',
    );
  }

  /// Refresh email context by re-fetching summaries
  Future<void> _refreshEmailContext() async {
    debugPrint('📧 [PDA EMAIL MONITOR] Refreshing email context...');

    try {
      final freshSummaries = await _gmailService.getRecentEmailSummaries(
        limit: 10,
      );
      _cachedEmailSummaries = freshSummaries;
      debugPrint(
        '📧 [PDA EMAIL MONITOR] Email context refreshed with ${freshSummaries.length} summaries',
      );
    } catch (e) {
      debugPrint('❌ [PDA EMAIL MONITOR] Error refreshing email context: $e');
    }
  }

  /// Get Document context for PDA responses
  Future<String> _getDocumentContextForPda() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return '';

      final context = await _documentPrewarmService.getPrewarmedContext(
        userId: currentUserId,
      );
      return _formatDocumentContext(context);
    } catch (e) {
      debugPrint('❌ [PDA DOCUMENT CONTEXT] Error getting document context: $e');
      return '';
    }
  }

  String _formatDocumentContext(Map<String, dynamic> context) {
    if (context.isEmpty) return 'No document context available.';

    final totalDocuments = context['totalDocuments'] ?? 0;
    final recentDocuments = context['recentDocuments'] as List<dynamic>? ?? [];
    final documentCategories =
        context['documentCategories'] as Map<String, dynamic>? ?? {};
    final summary = context['summary'] ?? 'No overall summary.';
    final keywords = context['keywords'] as List<dynamic>? ?? [];

    String formattedRecentDocuments = '';
    List<String> documentsWithFullContent = [];

    if (recentDocuments.isNotEmpty) {
      formattedRecentDocuments = recentDocuments
          .map((doc) {
            final title = doc['title'] ?? 'Untitled';
            final docSummary = doc['summary'] ?? 'No summary.';
            final fileType = doc['fileType'] ?? 'unknown';
            final fileSize = doc['fileSize'] ?? 0;
            final uploadDate = doc['uploadDate'] ?? '';
            final category = doc['category'] ?? 'uncategorized';
            final originalName = doc['originalName'] ?? title;
            final wordCount = doc['wordCount'] ?? 0;
            final keywords = doc['keywords'] as List<dynamic>? ?? [];
            // final hasFullContent = doc['hasFullContent'] ?? false;
            // final fullContent = doc['fullContent'] ?? '';

            String docInfo =
                '- $title ($fileType, ${_formatFileSize(fileSize)})';
            docInfo += '\n  Summary: $docSummary';
            docInfo += '\n  Category: $category';
            docInfo += '\n  Upload Date: ${_formatDate(uploadDate)}';
            docInfo += '\n  Word Count: $wordCount';

            if (keywords.isNotEmpty) {
              docInfo += '\n  Keywords: ${keywords.join(', ')}';
            }

            final hasFileData = doc['hasFileData'] ?? false;
            final mimeType = doc['mimeType'] ?? '';

            if (hasFileData) {
              docInfo += '\n  📄 ACTUAL FILE AVAILABLE TO CLAUDE';
              docInfo += '\n  MIME Type: $mimeType';
              documentsWithFullContent.add('$title ($originalName)');
            } else {
              docInfo += '\n  ⚠️ File not available - only summary provided';
            }

            return docInfo;
          })
          .join('\n\n');
    } else {
      formattedRecentDocuments = 'No recent documents.';
    }

    String formattedCategories = '';
    if (documentCategories.isNotEmpty) {
      formattedCategories = documentCategories.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    } else {
      formattedCategories = 'No document categories.';
    }

    String contentInstructions = '';
    if (documentsWithFullContent.isNotEmpty) {
      contentInstructions =
          '''

📄 ACTUAL DOCUMENT FILES AVAILABLE:
The following documents are directly accessible to you as files:
${documentsWithFullContent.map((doc) => '• $doc').join('\n')}

IMPORTANT INSTRUCTIONS FOR DOCUMENT ANALYSIS:
1. You have direct access to the actual document files (PDFs, images, etc.)
2. You can analyze the complete document content, including text, images, tables, charts, and formatting
3. For PDFs: Read and analyze all text, extract data from tables, understand document structure
4. For Images: Analyze visual content, read text in images (OCR), describe what you see
5. For Office documents: Access full content including formatting, tables, and embedded elements
6. When users ask questions about these documents, analyze the actual files directly
7. Provide detailed, accurate answers based on the complete document analysis
8. Reference specific sections, pages, or visual elements from the documents when relevant

CAPABILITIES WITH ACTUAL FILES:
- Complete document analysis (text, images, tables, charts)
- Visual content analysis for images and diagrams
- Data extraction from structured documents
- Document comparison and cross-referencing
- Detailed content summarization
- Specific information lookup within documents
- Format-aware analysis (understanding document structure)
''';
    }

    final lastUpdated = context['updated_at'] ?? context['lastUpdated'] ?? '';
    final updatedInfo = lastUpdated.isNotEmpty
        ? '\nLast Updated: ${_formatDate(lastUpdated)}'
        : '';

    return '''
Total Documents: $totalDocuments
Recent Documents:
$formattedRecentDocuments
Document Categories: $formattedCategories
Overall Document Summary: $summary
Keywords: ${keywords.join(', ')}$updatedInfo$contentInstructions
''';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Get document files for Claude multimodal input with Gemini preprocessing
  Future<Map<String, dynamic>> _getDocumentFilesForClaude() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return {'files': [], 'geminiCost': 0.0};

      // Initialize cache service
      await _cacheService.initialize();

      final context = await _documentPrewarmService.getPrewarmedContext(
        userId: currentUserId,
      );

      final recentDocuments =
          context['recentDocuments'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> documentFiles = [];
      final List<Map<String, dynamic>> filesToProcess = [];

      debugPrint(
        '📄 [CLAUDE FILES] Processing ${recentDocuments.length} documents for Claude',
      );

      // First, collect all files that need processing
      for (int i = 0; i < recentDocuments.length; i++) {
        final doc = recentDocuments[i];
        final hasFileData = doc['hasFileData'] ?? false;
        final cachedLocally = doc['cachedLocally'] ?? false;
        final mimeType = doc['mimeType'] ?? '';
        final originalName = doc['originalName'] ?? 'Unknown';

        debugPrint(
          '📄 [CLAUDE FILES] Document $i: $originalName - hasFileData: $hasFileData, cachedLocally: $cachedLocally, mimeType: $mimeType',
        );

        if (hasFileData && cachedLocally && mimeType.isNotEmpty) {
          // Retrieve file data from local cache
          final cachedFileData = await _cacheService.getCachedFileData(
            userId: currentUserId,
            fileName: originalName,
          );

          if (cachedFileData != null) {
            filesToProcess.add({
              'base64Data': cachedFileData,
              'mimeType': mimeType,
              'fileName': originalName,
              'originalDoc': doc,
            });

            debugPrint(
              '📄 [CLAUDE FILES] ✅ Retrieved cached file data for: $originalName ($mimeType)',
            );
          } else {
            debugPrint(
              '📄 [CLAUDE FILES] ❌ Failed to retrieve cached file data for: $originalName',
            );
          }
        } else {
          debugPrint(
            '📄 [CLAUDE FILES] Skipping file $originalName - hasFileData: $hasFileData, cachedLocally: $cachedLocally, mimeType: $mimeType',
          );
        }
      }

      if (filesToProcess.isEmpty) {
        debugPrint('📄 [CLAUDE FILES] No files to process');
        return {'files': [], 'geminiCost': 0.0};
      }

      // Use Gemini to extract content from complex file types (PDFs, CSVs, etc.)
      String geminiExtractedContent = '';
      double totalGeminiCost = 0.0;
      if (_geminiProcessor.isConfigured) {
        debugPrint(
          '🔍 [GEMINI PREPROCESSING] Processing ${filesToProcess.length} files with Gemini for content extraction',
        );

        for (final file in filesToProcess) {
          final mimeType = file['mimeType'] as String;
          final fileName = file['fileName'] as String;
          final base64Data = file['base64Data'] as String;

          // Check if this file type benefits from Gemini preprocessing
          if (_shouldUseGeminiForFile(mimeType)) {
            debugPrint(
              '🔍 [GEMINI PREPROCESSING] Extracting content from $fileName ($mimeType)',
            );

            final extraction = await _geminiProcessor.extractFileContent(
              base64Data: base64Data,
              mimeType: mimeType,
              fileName: fileName,
            );

            if (extraction != null && extraction['success'] == true) {
              final extractedText = extraction['extractedText'] as String;
              geminiExtractedContent +=
                  '''

📄 **${fileName}** (${mimeType})
${extractedText}

---

''';

              // Calculate Gemini cost for this file processing
              final geminiInputTokens =
                  ApiCostLogger.estimateTokensFromBase64(base64Data, mimeType) +
                  1000; // +1000 for prompt
              final geminiOutputTokens = ApiCostLogger.estimateTokensFromText(
                extractedText,
              );
              final geminiCost = ApiCostLogger.calculateGeminiCost(
                inputTokens: geminiInputTokens,
                outputTokens: geminiOutputTokens,
              );
              totalGeminiCost += geminiCost;

              debugPrint(
                '✅ [GEMINI PREPROCESSING] Successfully extracted ${extractedText.length} characters from $fileName (Cost: \$${geminiCost.toStringAsFixed(6)})',
              );
            } else {
              debugPrint(
                '❌ [GEMINI PREPROCESSING] Failed to extract content from $fileName',
              );
            }
          }
        }
      } else {
        debugPrint(
          '⚠️ [GEMINI PREPROCESSING] Gemini not configured, skipping content extraction',
        );
      }

      // Add extracted content as text if available
      if (geminiExtractedContent.isNotEmpty) {
        documentFiles.add({
          'type': 'text',
          'text':
              '''
📄 EXTRACTED DOCUMENT CONTENT (via Gemini):

The following content has been extracted from your uploaded documents using advanced AI analysis:

$geminiExtractedContent

This extracted content provides detailed information from your documents that can be used to answer questions about their contents, analyze data, and provide insights.
''',
        });

        debugPrint(
          '📄 [CLAUDE FILES] ✅ Added Gemini-extracted content (${geminiExtractedContent.length} characters)',
        );
      }

      // Add original files for Claude's direct analysis (especially for images)
      for (final file in filesToProcess) {
        final mimeType = file['mimeType'] as String;
        final fileName = file['fileName'] as String;
        final base64Data = file['base64Data'] as String;

        // Always include images for Claude's visual analysis
        // For other file types, include them alongside Gemini extraction for comprehensive analysis
        if (mimeType.startsWith('image/') ||
            _shouldIncludeOriginalFile(mimeType)) {
          documentFiles.add({
            'type': 'image', // Claude uses 'image' type for all file types
            'source': {
              'type': 'base64',
              'media_type': mimeType,
              'data': base64Data,
            },
          });

          debugPrint(
            '📄 [CLAUDE FILES] ✅ Added original file to multimodal input: $fileName ($mimeType)',
          );
        }
      }

      debugPrint(
        '📄 [CLAUDE FILES] Total content prepared for Claude: ${documentFiles.length} items (${geminiExtractedContent.isNotEmpty ? 'with Gemini extraction' : 'original files only'})',
      );
      if (totalGeminiCost > 0) {
        debugPrint(
          '💰 [GEMINI COST] Total vault document preprocessing cost: \$${totalGeminiCost.toStringAsFixed(6)}',
        );
      }

      return {'files': documentFiles, 'geminiCost': totalGeminiCost};
    } catch (e) {
      debugPrint('❌ [CLAUDE FILES] Error preparing document files: $e');
      return {'files': [], 'geminiCost': 0.0};
    }
  }

  /// Check if file type should use Gemini for content extraction
  bool _shouldUseGeminiForFile(String mimeType) {
    // Use Gemini for complex file types that benefit from content extraction
    return mimeType.contains('pdf') ||
        mimeType.contains('csv') ||
        mimeType.contains('excel') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('word') ||
        mimeType.contains('document') ||
        mimeType.contains('text/plain');
  }

  /// Check if original file should be included alongside Gemini extraction
  bool _shouldIncludeOriginalFile(String mimeType) {
    // Only include image files for Claude's direct analysis
    // All other file types should be processed by Gemini only
    return mimeType.startsWith('image/') &&
        (mimeType.contains('jpeg') ||
            mimeType.contains('png') ||
            mimeType.contains('gif') ||
            mimeType.contains('webp'));
  }

  /// Quick sync calendar data for immediate refresh
  Future<void> quickSyncCalendarData() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('⚠️ [QUICK SYNC] User not authenticated');
        return;
      }

      debugPrint('⚡ [QUICK SYNC] Starting quick calendar sync...');

      // Force refresh calendar data
      if (_googleCalendarPrewarmService != null) {
        await _googleCalendarPrewarmService!.quickSyncForPDA(currentUserId);
      }

      debugPrint('✅ [QUICK SYNC] Quick calendar sync completed');
    } catch (e) {
      debugPrint('❌ [QUICK SYNC] Quick calendar sync error: $e');
    }
  }

  /// Get MIME type from file extension
  String _getMimeTypeFromFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Dispose resources
  void dispose() {
    stopEmailMonitoring();
    _gmailPrewarmService.dispose();
    _linkedInPrewarmService.dispose();
    // No explicit dispose needed for DocumentContextPrewarmService as it doesn't manage streams or external resources
  }
}
