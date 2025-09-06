import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../domain/repositories/simple_linkedin_repository.dart';
import '../../domain/entities/simple_linkedin_account.dart';
import '../../domain/entities/simple_linkedin_post.dart';
import '../data_sources/pda_vertex_ai_data_source_impl.dart';
import 'linkedin_cache_manager.dart';

/// Service to pre-warm PDA with LinkedIn context for faster responses
class LinkedInContextPrewarmService {
  static final LinkedInContextPrewarmService _instance =
      LinkedInContextPrewarmService._internal();
  factory LinkedInContextPrewarmService() => _instance;
  LinkedInContextPrewarmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  final LinkedInCacheManager _cacheManager = LinkedInCacheManager();

  // Cache for LinkedIn context
  Map<String, dynamic> _linkedInContextCache = {};

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
  SimpleLinkedInRepository get _repository {
    try {
      return _getIt<SimpleLinkedInRepository>();
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] Repository not found in GetIt: $e');
      throw Exception(
        'SimpleLinkedInRepository not registered. Make sure LinkedInModule.register() is called.',
      );
    }
  }

  PdaVertexAiDataSourceImpl? get _pdaDataSource {
    try {
      return _getIt<PdaVertexAiDataSourceImpl>();
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] PDA data source not found: $e');
      return null;
    }
  }

  /// Check if LinkedIn is connected for the current user
  Future<bool> isLinkedInConnected() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await _repository.isLinkedInConnected(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] Error checking connection status: $e');
      return false;
    }
  }

  /// Pre-warm PDA with LinkedIn context
  Future<void> prewarmLinkedInContext() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ [LINKEDIN PREWARM] No authenticated user');
        return;
      }

      debugPrint(
        '🚀 [LINKEDIN PREWARM] Starting LinkedIn context pre-warming...',
      );
      _prewarmStatusController.add(true);

      // Check if LinkedIn is connected
      final isConnected = await isLinkedInConnected();
      if (!isConnected) {
        debugPrint(
          'ℹ️ [LINKEDIN PREWARM] LinkedIn not connected, skipping pre-warming',
        );
        _prewarmStatusController.add(false);
        return;
      }

      // Check if cache is still valid
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [LINKEDIN PREWARM] Using cached LinkedIn context');
        final cachedContext = await _cacheManager.loadLinkedInContext();
        if (cachedContext.isNotEmpty) {
          _linkedInContextCache = cachedContext;
          await _updatePdaWithLinkedInContext(cachedContext);
          _prewarmStatusController.add(false);
          return;
        }
      }

      // Fetch fresh LinkedIn data
      final linkedInContext = await _fetchLinkedInContext(user.uid);

      if (linkedInContext.isNotEmpty) {
        // Cache the context
        _linkedInContextCache = linkedInContext;

        // Store context in local cache and Firestore
        await _cacheManager.storeLinkedInContext(linkedInContext);
        await _cacheManager.storeLinkedInContextInFirestore(linkedInContext);

        // Update PDA with LinkedIn context
        await _updatePdaWithLinkedInContext(linkedInContext);

        debugPrint(
          '✅ [LINKEDIN PREWARM] LinkedIn context pre-warmed successfully',
        );
        _contextUpdateController.add(linkedInContext);
      } else {
        debugPrint('⚠️ [LINKEDIN PREWARM] No LinkedIn context available');
      }

      _prewarmStatusController.add(false);
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] Error pre-warming LinkedIn context: $e');
      _prewarmStatusController.add(false);
    }
  }

  /// Fetch comprehensive LinkedIn context
  Future<Map<String, dynamic>> _fetchLinkedInContext(String userId) async {
    try {
      debugPrint('📊 [LINKEDIN PREWARM] Fetching LinkedIn context...');

      // Fetch LinkedIn data using SimpleLinkedInRepository (limited to available methods)
      final futures = await Future.wait([
        _repository.getLinkedInAccount(userId),
        _repository.getPosts(userId, limit: 20),
        _repository.getBasicAnalytics(userId),
      ]);

      final account = futures[0] as LinkedInAccount?;
      final posts = futures[1] as List<LinkedInPost>;
      final analytics = futures[2] as Map<String, dynamic>;

      // Create context with available data from SimpleLinkedInRepository
      final context = {
        'account': _serializeLinkedInAccount(account),
        'posts': posts.map((post) => _serializeLinkedInPost(post)).toList(),
        'analytics': analytics,
        'summary': _generateLinkedInSummary(
          account: account,
          posts: posts,
          analytics: analytics,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '📊 [LINKEDIN PREWARM] LinkedIn context fetched: ${posts.length} posts',
      );
      return context;
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] Error fetching LinkedIn context: $e');
      return {};
    }
  }

  /// Serialize LinkedIn account to JSON
  Map<String, dynamic>? _serializeLinkedInAccount(LinkedInAccount? account) {
    if (account == null) return null;
    return {
      'id': account.id,
      'userId': account.userId,
      'linkedinId': account.linkedinId,
      'email': account.email,
      'firstName': account.firstName,
      'lastName': account.lastName,
      'headline': account.headline,
      'profilePictureUrl': account.profilePictureUrl,
      'vanityName': account.vanityName,
      'locationName': account.locationName,
      'locationCountry': account.locationCountry,
      'connectedAt': account.connectedAt.toIso8601String(),
      'lastSyncedAt': account.lastSyncedAt?.toIso8601String(),
      'isActive': account.isActive,
    };
  }

  /// Serialize LinkedIn post to JSON
  Map<String, dynamic> _serializeLinkedInPost(LinkedInPost post) {
    return {
      'id': post.id,
      'postId': post.postId,
      'content': post.content,
      'postType': post.postType,
      'visibility': post.visibility,
      'mediaUrls': post.mediaUrls,
      'articleUrl': post.articleUrl,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'shareCount': post.shareCount,
      'postedAt': post.postedAt?.toIso8601String(),
      'fetchedAt': post.fetchedAt.toIso8601String(),
    };
  }

  /// Generate a comprehensive LinkedIn summary for PDA context
  String _generateLinkedInSummary({
    LinkedInAccount? account,
    required List<LinkedInPost> posts,
    required Map<String, dynamic> analytics,
  }) {
    final buffer = StringBuffer();

    // Account summary
    if (account != null) {
      buffer.writeln('LinkedIn Profile:');
      buffer.writeln(
        '- Name: ${account.firstName ?? 'Unknown'} ${account.lastName ?? 'Unknown'}',
      );
      buffer.writeln('- Headline: ${account.headline ?? 'Not provided'}');
      buffer.writeln(
        '- Location: ${account.locationName ?? account.locationCountry ?? 'Not provided'}',
      );
      buffer.writeln('- LinkedIn ID: ${account.linkedinId}');
      buffer.writeln('- Connected: ${account.connectedAt}');
      buffer.writeln('- Active: ${account.isActive}');
      buffer.writeln();
    }

    // Note: Professional experience, education, and skills data not available in SimpleLinkedInRepository

    // Recent activity summary
    if (posts.isNotEmpty) {
      buffer.writeln('Recent Activity:');
      buffer.writeln('- Recent Posts: ${posts.length}');
      final totalEngagement = posts.fold<int>(
        0,
        (sum, post) =>
            sum + post.likeCount + post.commentCount + post.shareCount,
      );
      buffer.writeln('- Total Engagement: $totalEngagement');
      buffer.writeln();
    }

    // Analytics summary
    if (analytics.isNotEmpty) {
      buffer.writeln('Analytics:');
      buffer.writeln('- Available Metrics: ${analytics.keys.join(', ')}');
    }

    return buffer.toString();
  }

  /// Update PDA with LinkedIn context
  Future<void> _updatePdaWithLinkedInContext(
    Map<String, dynamic> context,
  ) async {
    try {
      final pdaDataSource = _pdaDataSource;
      if (pdaDataSource == null) {
        debugPrint('⚠️ [LINKEDIN PREWARM] PDA data source not available');
        return;
      }

      // Store LinkedIn context in PDA's context cache
      await _storeLinkedInContextInPdaCache(context);

      debugPrint('🧠 [LINKEDIN PREWARM] PDA updated with LinkedIn context');
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error updating PDA with LinkedIn context: $e',
      );
    }
  }

  /// Store LinkedIn context in PDA's internal cache
  Future<void> _storeLinkedInContextInPdaCache(
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
          .doc('linkedin')
          .set({
            'context': context,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': '1.0',
          });

      debugPrint('💾 [LINKEDIN PREWARM] LinkedIn context stored in PDA cache');
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error storing LinkedIn context in PDA cache: $e',
      );
    }
  }

  /// Load LinkedIn context from cache
  Future<Map<String, dynamic>> loadLinkedInContextFromCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Check memory cache first
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [LINKEDIN PREWARM] Loading from memory cache');
        return _linkedInContextCache;
      }

      // Load from local cache
      final localContext = await _cacheManager.loadLinkedInContext();
      if (localContext.isNotEmpty) {
        _linkedInContextCache = localContext;
        debugPrint('📦 [LINKEDIN PREWARM] Loaded from local cache');
        return localContext;
      }

      // Load from Firestore cache
      final firestoreContext = await _cacheManager
          .loadLinkedInContextFromFirestore();
      if (firestoreContext.isNotEmpty) {
        _linkedInContextCache = firestoreContext;
        debugPrint('📦 [LINKEDIN PREWARM] Loaded from Firestore cache');
        return firestoreContext;
      }

      debugPrint('📦 [LINKEDIN PREWARM] No cached context found');
      return {};
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error loading LinkedIn context from cache: $e',
      );
      return {};
    }
  }

  /// Clear LinkedIn context cache
  Future<void> clearLinkedInContextCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear memory cache
      _linkedInContextCache.clear();

      // Clear all caches using cache manager
      await _cacheManager.clearAllCaches();

      // Clear PDA context cache
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pda_context')
          .doc('linkedin')
          .delete();

      debugPrint('🧹 [LINKEDIN PREWARM] LinkedIn context cache cleared');
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error clearing LinkedIn context cache: $e',
      );
    }
  }

  /// Get LinkedIn context for PDA responses
  Future<String> getLinkedInContextForPda() async {
    try {
      // Try to get from cache first
      final context = await loadLinkedInContextFromCache();

      if (context.isNotEmpty && context['summary'] != null) {
        return context['summary'] as String;
      }

      // If no cache, try to pre-warm quickly
      final user = _auth.currentUser;
      if (user != null) {
        final quickContext = await _fetchLinkedInContext(user.uid);
        if (quickContext.isNotEmpty && quickContext['summary'] != null) {
          return quickContext['summary'] as String;
        }
      }

      return 'LinkedIn context not available.';
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error getting LinkedIn context for PDA: $e',
      );
      return 'LinkedIn context not available.';
    }
  }

  /// Start monitoring LinkedIn connection changes
  void startLinkedInMonitoring() {
    debugPrint('👁️ [LINKEDIN PREWARM] Starting LinkedIn monitoring...');

    // Monitor authentication state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, check LinkedIn connection and pre-warm if needed
        _checkAndPrewarmOnAuthChange();
      } else {
        // User signed out, clear cache
        clearLinkedInContextCache();
      }
    });
  }

  /// Check and pre-warm LinkedIn context on authentication changes
  Future<void> _checkAndPrewarmOnAuthChange() async {
    try {
      final isConnected = await isLinkedInConnected();
      if (isConnected) {
        debugPrint(
          '🔄 [LINKEDIN PREWARM] LinkedIn connected, pre-warming context...',
        );
        await prewarmLinkedInContext();
      }
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN PREWARM] Error checking LinkedIn on auth change: $e',
      );
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _cacheManager.getCacheStats();
    } catch (e) {
      debugPrint('❌ [LINKEDIN PREWARM] Error getting cache stats: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _prewarmStatusController.close();
    _contextUpdateController.close();
  }
}
