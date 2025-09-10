import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/gmail_repository.dart';
import '../../domain/entities/gmail_account.dart';
import '../../domain/entities/gmail_email.dart';
import '../data_sources/pda_vertex_ai_data_source_impl.dart';
import 'linkedin_cache_manager.dart';

/// Service to pre-warm PDA with Gmail context for faster responses
class GmailContextPrewarmService {
  static final GmailContextPrewarmService _instance =
      GmailContextPrewarmService._internal();
  factory GmailContextPrewarmService() => _instance;
  GmailContextPrewarmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  final LinkedInCacheManager _cacheManager = LinkedInCacheManager();

  // Cache for Gmail context
  Map<String, dynamic> _gmailContextCache = {};

  // Stream controllers for real-time updates
  final StreamController<bool> _prewarmStatusController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _contextUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<bool> get prewarmStatusStream => _prewarmStatusController.stream;
  Stream<Map<String, dynamic>> get contextUpdateStream =>
      _contextUpdateController.stream;

  // Lazy getters for dependencies
  GmailRepository get _repository {
    try {
      return _getIt<GmailRepository>();
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Repository not found in GetIt: $e');
      throw Exception(
        'GmailRepository not registered. Make sure GmailModule.register() is called.',
      );
    }
  }

  PdaVertexAiDataSourceImpl? get _pdaDataSource {
    try {
      return _getIt<PdaVertexAiDataSourceImpl>();
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] PDA data source not found: $e');
      return null;
    }
  }

  /// Check if Gmail is connected for the current user
  Future<bool> isGmailConnected() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await _repository.isGmailConnected(user.uid);
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error checking connection status: $e');
      return false;
    }
  }

  /// Pre-warm PDA with Gmail context
  Future<void> prewarmGmailContext() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ [GMAIL PREWARM] No authenticated user');
        return;
      }

      debugPrint('🚀 [GMAIL PREWARM] Starting Gmail context pre-warming...');
      _prewarmStatusController.add(true);

      // Check if Gmail is connected
      final isConnected = await isGmailConnected();
      if (!isConnected) {
        debugPrint(
          'ℹ️ [GMAIL PREWARM] Gmail not connected, skipping pre-warming',
        );
        _prewarmStatusController.add(false);
        return;
      }

      // Check if cache is still valid
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [GMAIL PREWARM] Using cached Gmail context');
        final cachedContext = await _loadGmailContextFromCache();
        if (cachedContext.isNotEmpty) {
          _gmailContextCache = cachedContext;
          await _updatePdaWithGmailContext(cachedContext);
          _prewarmStatusController.add(false);
          return;
        }
      }

      // Fetch fresh Gmail data
      final gmailContext = await _fetchGmailContext(user.uid);

      if (gmailContext.isNotEmpty) {
        // Cache the context
        _gmailContextCache = gmailContext;

        // Store context in local cache only (skip Firestore to avoid size limits)
        await _storeGmailContextInCache(gmailContext);
        // Skip Firestore storage to avoid size limits with large email datasets

        // Update PDA with Gmail context
        await _updatePdaWithGmailContext(gmailContext);

        debugPrint('✅ [GMAIL PREWARM] Gmail context pre-warmed successfully');
        _contextUpdateController.add(gmailContext);
      } else {
        debugPrint('⚠️ [GMAIL PREWARM] No Gmail context available');
      }

      _prewarmStatusController.add(false);
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error pre-warming Gmail context: $e');
      _prewarmStatusController.add(false);
    }
  }

  /// Fetch comprehensive Gmail context
  Future<Map<String, dynamic>> _fetchGmailContext(String userId) async {
    try {
      debugPrint('📊 [GMAIL PREWARM] Fetching Gmail context...');

      // Get account info first
      final account = await _repository.getGmailAccount(userId);

      // Get ALL emails for comprehensive context
      debugPrint('📊 [GMAIL PREWARM] Fetching ALL emails from database...');
      final allEmails = await _repository.getEmails(
        userId,
      ); // No limit = get ALL emails

      debugPrint(
        '📊 [GMAIL PREWARM] Retrieved ${allEmails.length} total emails',
      );

      // Filter emails by status for different categories
      final recentEmails = allEmails; // All emails are recent in this context
      final unreadEmails = allEmails.where((email) => !email.isRead).toList();
      final importantEmails = allEmails
          .where((email) => email.isImportant)
          .toList();

      // Create comprehensive context
      final context = {
        'account': _serializeGmailAccount(account),
        'recentEmails': recentEmails
            .map((email) => _serializeGmailEmail(email))
            .toList(),
        'unreadEmails': unreadEmails
            .map((email) => _serializeGmailEmail(email))
            .toList(),
        'importantEmails': importantEmails
            .map((email) => _serializeGmailEmail(email))
            .toList(),
        'summary': _generateGmailSummary(
          account: account,
          recentEmails: recentEmails,
          unreadEmails: unreadEmails,
          importantEmails: importantEmails,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '📊 [GMAIL PREWARM] Gmail context fetched: ${allEmails.length} total emails (${unreadEmails.length} unread, ${importantEmails.length} important)',
      );
      return context;
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error fetching Gmail context: $e');
      return {};
    }
  }

  /// Serialize Gmail account to JSON
  Map<String, dynamic>? _serializeGmailAccount(GmailAccount? account) {
    if (account == null) return null;
    return {
      'userId': account.userId,
      'email': account.email,
      'isConnected': account.isConnected,
      'lastSyncAt': account.lastSyncAt?.toIso8601String(),
      'connectedAt': account.connectedAt?.toIso8601String(),
    };
  }

  /// Serialize Gmail email to JSON
  Map<String, dynamic> _serializeGmailEmail(GmailEmail email) {
    return {
      'messageId': email.messageId,
      'threadId': email.threadId,
      'subject': email.subject,
      'fromEmail': email.fromEmail,
      'fromName': email.fromName,
      'toEmails': email.toEmails,
      'ccEmails': email.ccEmails,
      'bccEmails': email.bccEmails,
      'bodyText': email.bodyText, // Include email body content
      'bodyHtml': email.bodyHtml, // Include HTML body content
      'snippet': email.snippet,
      'isRead': email.isRead,
      'isImportant': email.isImportant,
      'isStarred': email.isStarred,
      'labels': email.labels,
      'attachments': email.attachments,
      'receivedAt': email.receivedAt.toIso8601String(),
      'sentAt': email.sentAt?.toIso8601String(),
    };
  }

  /// Generate a comprehensive Gmail summary for PDA context
  String _generateGmailSummary({
    GmailAccount? account,
    required List<GmailEmail> recentEmails,
    required List<GmailEmail> unreadEmails,
    required List<GmailEmail> importantEmails,
  }) {
    final buffer = StringBuffer();

    // Account summary
    if (account != null) {
      buffer.writeln('Gmail Account:');
      buffer.writeln('- Email: ${account.email}');
      buffer.writeln('- Connected: ${account.isConnected}');
      if (account.lastSyncAt != null) {
        buffer.writeln('- Last Sync: ${account.lastSyncAt}');
      }
      buffer.writeln();
    }

    // Email statistics
    buffer.writeln('Email Statistics:');
    buffer.writeln('- Total Emails in Context: ${recentEmails.length}');
    buffer.writeln('- Unread Emails: ${unreadEmails.length}');
    buffer.writeln('- Important Emails: ${importantEmails.length}');
    buffer.writeln();

    // Email activity (showing ALL emails from all time periods)
    if (recentEmails.isNotEmpty) {
      buffer.writeln('ALL Email Activity (complete email history):');

      // Show ALL emails - no limits
      for (int i = 0; i < recentEmails.length; i++) {
        final email = recentEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        final isRead = email.isRead ? 'Read' : 'Unread';
        final receivedDate = email.receivedAt.toLocal().toString().split(
          ' ',
        )[0];

        buffer.writeln('--- Email ${i + 1} ---');
        buffer.writeln('From: $from');
        buffer.writeln('Subject: $subject');
        buffer.writeln('Date: $receivedDate');
        buffer.writeln('Status: $isRead');

        // Include email body content if available
        if (email.bodyText != null && email.bodyText!.isNotEmpty) {
          final bodyPreview = email.bodyText!.length > 200
              ? '${email.bodyText!.substring(0, 200)}...'
              : email.bodyText!;
          buffer.writeln('Content: $bodyPreview');
        } else if (email.snippet != null && email.snippet!.isNotEmpty) {
          buffer.writeln('Snippet: ${email.snippet}');
        }

        buffer.writeln();
      }
    }

    // Unread emails summary with content
    if (unreadEmails.isNotEmpty) {
      buffer.writeln('ALL Unread Emails (with content):');
      for (int i = 0; i < unreadEmails.length; i++) {
        final email = unreadEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        final receivedDate = email.receivedAt.toLocal().toString().split(
          ' ',
        )[0];

        buffer.writeln('--- Unread Email ${i + 1} ---');
        buffer.writeln('From: $from');
        buffer.writeln('Subject: $subject');
        buffer.writeln('Date: $receivedDate');

        // Include email body content if available
        if (email.bodyText != null && email.bodyText!.isNotEmpty) {
          final bodyPreview = email.bodyText!.length > 150
              ? '${email.bodyText!.substring(0, 150)}...'
              : email.bodyText!;
          buffer.writeln('Content: $bodyPreview');
        } else if (email.snippet != null && email.snippet!.isNotEmpty) {
          buffer.writeln('Snippet: ${email.snippet}');
        }

        buffer.writeln();
      }
    }

    // Important emails summary with content
    if (importantEmails.isNotEmpty) {
      buffer.writeln('ALL Important Emails (with content):');
      for (int i = 0; i < importantEmails.length; i++) {
        final email = importantEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        final receivedDate = email.receivedAt.toLocal().toString().split(
          ' ',
        )[0];

        buffer.writeln('--- Important Email ${i + 1} ---');
        buffer.writeln('From: $from');
        buffer.writeln('Subject: $subject');
        buffer.writeln('Date: $receivedDate');

        // Include email body content if available
        if (email.bodyText != null && email.bodyText!.isNotEmpty) {
          final bodyPreview = email.bodyText!.length > 150
              ? '${email.bodyText!.substring(0, 150)}...'
              : email.bodyText!;
          buffer.writeln('Content: $bodyPreview');
        } else if (email.snippet != null && email.snippet!.isNotEmpty) {
          buffer.writeln('Snippet: ${email.snippet}');
        }

        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Update PDA with Gmail context
  Future<void> _updatePdaWithGmailContext(Map<String, dynamic> context) async {
    try {
      final pdaDataSource = _pdaDataSource;
      if (pdaDataSource == null) {
        debugPrint('⚠️ [GMAIL PREWARM] PDA data source not available');
        return;
      }

      // Store Gmail context in PDA's context cache
      await _storeGmailContextInPdaCache(context);

      debugPrint('🧠 [GMAIL PREWARM] PDA updated with Gmail context');
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error updating PDA with Gmail context: $e');
    }
  }

  /// Store Gmail context in PDA's internal cache (local only)
  Future<void> _storeGmailContextInPdaCache(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Store locally only to avoid Firestore size limits
      final prefs = await SharedPreferences.getInstance();
      final contextJson = jsonEncode(context);
      await prefs.setString('gmail_pda_context_${user.uid}', contextJson);
      await prefs.setString(
        'gmail_pda_context_timestamp_${user.uid}',
        DateTime.now().toIso8601String(),
      );

      debugPrint('💾 [GMAIL PREWARM] Gmail context stored in local PDA cache');
    } catch (e) {
      debugPrint(
        '❌ [GMAIL PREWARM] Error storing Gmail context in PDA cache: $e',
      );
    }
  }

  /// Store Gmail context in local cache
  Future<void> _storeGmailContextInCache(Map<String, dynamic> context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final contextJson = jsonEncode(context);
      await prefs.setString('gmail_context_cache', contextJson);
      await prefs.setString(
        'gmail_context_last_update',
        DateTime.now().toIso8601String(),
      );

      debugPrint('💾 [GMAIL PREWARM] Gmail context stored in local cache');
    } catch (e) {
      debugPrint(
        '❌ [GMAIL PREWARM] Error storing Gmail context in local cache: $e',
      );
    }
  }

  /// Load Gmail context from cache
  Future<Map<String, dynamic>> _loadGmailContextFromCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Check memory cache first
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [GMAIL PREWARM] Loading from memory cache');
        return _gmailContextCache;
      }

      // Load from local cache
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString('gmail_context_cache');
      if (contextJson != null) {
        final context = jsonDecode(contextJson) as Map<String, dynamic>;
        _gmailContextCache = context;
        debugPrint('📦 [GMAIL PREWARM] Loaded from local cache');
        return context;
      }

      // Load from Firestore cache
      final doc = await _firestore
          .collection('gmail_context_cache')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final context = data['context'] as Map<String, dynamic>?;
        if (context != null) {
          _gmailContextCache = context;
          debugPrint('📦 [GMAIL PREWARM] Loaded from Firestore cache');
          return context;
        }
      }

      debugPrint('📦 [GMAIL PREWARM] No cached context found');
      return {};
    } catch (e) {
      debugPrint(
        '❌ [GMAIL PREWARM] Error loading Gmail context from cache: $e',
      );
      return {};
    }
  }

  /// Clear Gmail context cache
  Future<void> clearGmailContextCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear memory cache
      _gmailContextCache.clear();

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gmail_context_cache');
      await prefs.remove('gmail_context_last_update');
      await prefs.remove('gmail_pda_context_${user.uid}');
      await prefs.remove('gmail_pda_context_timestamp_${user.uid}');

      debugPrint('🧹 [GMAIL PREWARM] Gmail context cache cleared (local only)');
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error clearing Gmail context cache: $e');
    }
  }

  /// Get Gmail context for PDA responses
  Future<String> getGmailContextForPda() async {
    try {
      // Try to get from cache first
      final context = await _loadGmailContextFromCache();

      if (context.isNotEmpty && context['summary'] != null) {
        final summary = context['summary'] as String;
        final recentEmails = context['recentEmails'] as List<dynamic>? ?? [];

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

      // If no cache, try to pre-warm quickly
      final user = _auth.currentUser;
      if (user != null) {
        final quickContext = await _fetchGmailContext(user.uid);
        if (quickContext.isNotEmpty && quickContext['summary'] != null) {
          final summary = quickContext['summary'] as String;
          final recentEmails =
              quickContext['recentEmails'] as List<dynamic>? ?? [];

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
      }

      return 'Gmail context not available.';
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error getting Gmail context for PDA: $e');
      return 'Gmail context not available.';
    }
  }

  /// Start monitoring Gmail connection changes
  void startGmailMonitoring() {
    debugPrint('👁️ [GMAIL PREWARM] Starting Gmail monitoring...');

    // Monitor authentication state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, check Gmail connection and pre-warm if needed
        _checkAndPrewarmOnAuthChange();
      } else {
        // User signed out, clear cache
        clearGmailContextCache();
      }
    });
  }

  /// Check and pre-warm Gmail context on authentication changes
  Future<void> _checkAndPrewarmOnAuthChange() async {
    try {
      final isConnected = await isGmailConnected();
      if (isConnected) {
        debugPrint(
          '🔄 [GMAIL PREWARM] Gmail connected, pre-warming context...',
        );
        await prewarmGmailContext();
      }
    } catch (e) {
      debugPrint('❌ [GMAIL PREWARM] Error checking Gmail on auth change: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _prewarmStatusController.close();
    _contextUpdateController.close();
  }
}
