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

        // Store context in local cache and Firestore
        await _storeGmailContextInCache(gmailContext);
        await _storeGmailContextInFirestore(gmailContext);

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

      // Fetch Gmail data in parallel for efficiency
      final futures = await Future.wait([
        _repository.getGmailAccount(userId),
        _repository.getEmails(userId, limit: 50),
        _repository.getEmails(userId, limit: 20),
        _repository.getEmails(userId, limit: 10),
      ]);

      final account = futures[0] as GmailAccount?;
      final recentEmails = futures[1] as List<GmailEmail>;
      final unreadEmails = futures[2] as List<GmailEmail>;
      final importantEmails = futures[3] as List<GmailEmail>;

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
        '📊 [GMAIL PREWARM] Gmail context fetched: ${recentEmails.length} recent emails, ${unreadEmails.length} unread, ${importantEmails.length} important',
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
      'snippet': email.snippet,
      'isRead': email.isRead,
      'isImportant': email.isImportant,
      'isStarred': email.isStarred,
      'labels': email.labels,
      'receivedAt': email.receivedAt.toIso8601String(),
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
    buffer.writeln('- Total Recent Emails: ${recentEmails.length}');
    buffer.writeln('- Unread Emails: ${unreadEmails.length}');
    buffer.writeln('- Important Emails: ${importantEmails.length}');
    buffer.writeln();

    // Recent email activity
    if (recentEmails.isNotEmpty) {
      buffer.writeln('Recent Email Activity:');
      final recentCount = recentEmails.take(5).length;
      for (int i = 0; i < recentCount; i++) {
        final email = recentEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        final isRead = email.isRead ? 'Read' : 'Unread';
        buffer.writeln('- $from: $subject ($isRead)');
      }
      buffer.writeln();
    }

    // Unread emails summary
    if (unreadEmails.isNotEmpty) {
      buffer.writeln('Unread Emails Summary:');
      final unreadCount = unreadEmails.take(3).length;
      for (int i = 0; i < unreadCount; i++) {
        final email = unreadEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        buffer.writeln('- $from: $subject');
      }
      buffer.writeln();
    }

    // Important emails summary
    if (importantEmails.isNotEmpty) {
      buffer.writeln('Important Emails:');
      final importantCount = importantEmails.take(3).length;
      for (int i = 0; i < importantCount; i++) {
        final email = importantEmails[i];
        final from = email.fromName ?? email.fromEmail ?? 'Unknown';
        final subject = email.subject ?? 'No Subject';
        buffer.writeln('- $from: $subject');
      }
      buffer.writeln();
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

  /// Store Gmail context in PDA's internal cache
  Future<void> _storeGmailContextInPdaCache(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Store in Firestore under user's PDA context (using HushUsers collection)
      await _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('pda_context')
          .doc('gmail')
          .set({
            'context': context,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': '1.0',
          });

      debugPrint('💾 [GMAIL PREWARM] Gmail context stored in PDA cache');
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

  /// Store Gmail context in Firestore for persistence
  Future<void> _storeGmailContextInFirestore(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('gmail_context_cache').doc(user.uid).set({
        'context': context,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      });

      debugPrint('💾 [GMAIL PREWARM] Gmail context stored in Firestore');
    } catch (e) {
      debugPrint(
        '❌ [GMAIL PREWARM] Error storing Gmail context in Firestore: $e',
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

      // Clear Firestore cache
      await _firestore.collection('gmail_context_cache').doc(user.uid).delete();

      // Clear PDA context cache
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pda_context')
          .doc('gmail')
          .delete();

      debugPrint('🧹 [GMAIL PREWARM] Gmail context cache cleared');
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
        return context['summary'] as String;
      }

      // If no cache, try to pre-warm quickly
      final user = _auth.currentUser;
      if (user != null) {
        final quickContext = await _fetchGmailContext(user.uid);
        if (quickContext.isNotEmpty && quickContext['summary'] != null) {
          return quickContext['summary'] as String;
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
