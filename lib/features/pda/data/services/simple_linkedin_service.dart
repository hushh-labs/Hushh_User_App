import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/simple_linkedin_account.dart';
import '../../domain/entities/simple_linkedin_post.dart';
import '../../domain/repositories/simple_linkedin_repository.dart';
import 'linkedin_context_prewarm_service.dart';

class LinkedInConnectionResult {
  final bool success;
  final String message;
  final LinkedInAccount? account;

  LinkedInConnectionResult.success(this.message, {this.account})
    : success = true;
  LinkedInConnectionResult.failure(this.message)
    : success = false,
      account = null;
}

class LinkedInSyncOptions {
  final bool includeProfile;
  final bool includePosts;

  const LinkedInSyncOptions({
    this.includeProfile = true,
    this.includePosts = false, // Requires "Share on LinkedIn" product approval
  });
}

class SupabaseLinkedInService {
  final GetIt _getIt = GetIt.instance;
  final LinkedInContextPrewarmService _prewarmService =
      LinkedInContextPrewarmService();

  // Stream controllers for real-time updates
  final StreamController<LinkedInAccount?> _accountController =
      StreamController<LinkedInAccount?>.broadcast();
  final StreamController<List<LinkedInPost>> _postsController =
      StreamController<List<LinkedInPost>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isMonitoringData = false;

  // Getters for streams
  Stream<LinkedInAccount?> get accountStream => _accountController.stream;
  Stream<List<LinkedInPost>> get postsStream => _postsController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  // Lazy getters for dependencies
  SimpleLinkedInRepository get _repository {
    try {
      return _getIt<SimpleLinkedInRepository>();
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Repository not found in GetIt: $e');
      throw Exception(
        'SimpleLinkedInRepository not registered. Make sure LinkedInModule.register() is called.',
      );
    }
  }

  firebase_auth.User? get _auth {
    return firebase_auth.FirebaseAuth.instance.currentUser;
  }

  // LinkedIn OAuth configuration
  String get _linkedInClientId {
    final clientId = dotenv.env['LINKEDIN_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      debugPrint(
        '❌ [LINKEDIN SERVICE] LINKEDIN_CLIENT_ID not found in .env file',
      );
      return '';
    }
    return clientId;
  }

  String get _linkedInRedirectUri {
    final redirectUri = dotenv.env['LINKEDIN_REDIRECT_URI'];
    return redirectUri ??
        'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/linkedin-comprehensive-sync';
  }

  /// Check if LinkedIn is connected for the current user
  Future<bool> isLinkedInConnected() async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return false;
      }
      return await _repository.isLinkedInConnected(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error checking connection status: $e');
      return false;
    }
  }

  /// Get LinkedIn account for current user
  Future<LinkedInAccount?> getLinkedInAccount() async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return null;
      }
      return await _repository.getLinkedInAccount(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting LinkedIn account: $e');
      return null;
    }
  }

  /// Connect LinkedIn account with simplified OAuth flow
  Future<LinkedInConnectionResult> connectLinkedIn() async {
    try {
      debugPrint('🔐 [LINKEDIN SERVICE] Starting LinkedIn OAuth...');

      final user = _auth;
      if (user == null) {
        return LinkedInConnectionResult.failure(
          'User not authenticated. Please log in first.',
        );
      }

      if (_linkedInClientId.isEmpty) {
        return LinkedInConnectionResult.failure(
          'LinkedIn client ID not configured',
        );
      }

      final authUrl = _generateLinkedInAuthUrl();
      debugPrint('🔐 [LINKEDIN SERVICE] Auth URL: $authUrl');

      // Launch OAuth in external browser
      final uri = Uri.parse(authUrl);
      final result = await launchUrl(uri, mode: LaunchMode.externalApplication);

      debugPrint('🔐 [LINKEDIN SERVICE] External browser launched: $result');

      if (result) {
        // Give user time to complete the OAuth flow in external browser
        debugPrint('🔐 [LINKEDIN SERVICE] Waiting for OAuth completion...');

        // Wait a bit for user to complete OAuth, then check connection status
        await Future.delayed(const Duration(seconds: 3));

        // Check if connection was successful by polling our database
        for (int i = 0; i < 10; i++) {
          final isConnected = await isLinkedInConnected();
          if (isConnected) {
            debugPrint('✅ [LINKEDIN SERVICE] OAuth completed successfully!');
            _connectionController.add(true);
            await _refreshDataStreams();
            final account = await getLinkedInAccount();

            // Pre-warm PDA with LinkedIn context after successful connection
            _prewarmService.prewarmLinkedInContext();

            return LinkedInConnectionResult.success(
              'LinkedIn connected successfully!',
              account: account,
            );
          }
          debugPrint(
            '🔄 [LINKEDIN SERVICE] Checking connection status... (${i + 1}/10)',
          );
          await Future.delayed(const Duration(seconds: 2));
        }

        return LinkedInConnectionResult.failure(
          'OAuth completed but connection not detected. Please try again.',
        );
      } else {
        return LinkedInConnectionResult.failure('Could not launch OAuth URL');
      }
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] OAuth error: $e');
      return LinkedInConnectionResult.failure('OAuth failed: $e');
    }
  }

  /// Generate LinkedIn OAuth authorization URL (simplified scopes)
  String _generateLinkedInAuthUrl() {
    // Enhanced scopes for comprehensive data access with Share on LinkedIn product
    final scopes = [
      'openid',
      'profile',
      'email',
      'w_member_social', // Share on LinkedIn - allows posting and reading social content
    ].join(' ');
    final user = _auth;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final userId = user.uid; // Get current user ID
    final state = '${DateTime.now().millisecondsSinceEpoch}-$userId';

    // Use clean redirect URI (no API key needed since OAuth callback is now allowed)
    final params = {
      'response_type': 'code',
      'client_id': _linkedInClientId,
      'redirect_uri': _linkedInRedirectUri,
      'scope': scopes,
      'state': state,
    };

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final authUrl = 'https://www.linkedin.com/oauth/v2/authorization?$query';
    debugPrint('🔗 [LINKEDIN SERVICE] Generated Auth URL: $authUrl');
    debugPrint('🔗 [LINKEDIN SERVICE] Redirect URI: $_linkedInRedirectUri');

    return authUrl;
  }

  /// Disconnect LinkedIn account
  Future<bool> disconnectLinkedIn() async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return false;
      }
      final success = await _repository.disconnectLinkedIn(user.uid);

      if (success) {
        _connectionController.add(false);
        _accountController.add(null);
        _postsController.add([]);

        // Clear LinkedIn context cache when disconnected
        _prewarmService.clearLinkedInContextCache();
      }

      return success;
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error disconnecting LinkedIn: $e');
      return false;
    }
  }

  /// Sync LinkedIn data with realistic options
  Future<bool> syncLinkedInData([LinkedInSyncOptions? options]) async {
    try {
      // Check if LinkedIn is connected
      final isConnected = await isLinkedInConnected();
      if (!isConnected) {
        return false;
      }

      final syncOptions = options ?? const LinkedInSyncOptions();
      debugPrint(
        '🔄 [LINKEDIN SERVICE] Syncing data: profile=${syncOptions.includeProfile}, posts=${syncOptions.includePosts}',
      );

      // Call Edge Function to sync data from LinkedIn API
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return false;
      }

      final userId = user.uid;
      final account = await getLinkedInAccount();

      if (account?.accessToken == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No access token available for sync');
        return false;
      }

      try {
        final response = await Supabase.instance.client.functions.invoke(
          'linkedin-simple-sync',
          body: {'accessToken': account!.accessToken, 'userId': userId},
        );

        if (response.status == 200) {
          // Update local last_synced_at
          await _repository.syncData(userId, syncOptions);

          // Pre-warm PDA with updated LinkedIn context after sync
          _prewarmService.prewarmLinkedInContext();

          return true;
        } else {
          debugPrint('❌ [LINKEDIN SERVICE] Sync failed: ${response.status}');
          return false;
        }
      } catch (e) {
        debugPrint('❌ [LINKEDIN SERVICE] Sync error: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error syncing LinkedIn data: $e');
      return false;
    }
  }

  /// Get LinkedIn posts for current user
  Future<List<LinkedInPost>> getPosts({int limit = 50, int offset = 0}) async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return [];
      }
      return await _repository.getPosts(user.uid, limit: limit, offset: offset);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting posts: $e');
      return [];
    }
  }

  /// Get posts count
  Future<int> getPostsCount() async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return 0;
      }
      return await _repository.getPostsCount(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting posts count: $e');
      return 0;
    }
  }

  /// Search posts by content
  Future<List<LinkedInPost>> searchPosts(String query) async {
    try {
      final user = _auth;
      if (user == null) {
        debugPrint('❌ [LINKEDIN SERVICE] No authenticated user');
        return [];
      }
      return await _repository.searchPosts(user.uid, query);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error searching posts: $e');
      return [];
    }
  }

  /// Get basic analytics
  Future<Map<String, dynamic>> getBasicAnalytics() async {
    try {
      final account = await getLinkedInAccount();
      final postsCount = await getPostsCount();
      final posts = await getPosts(limit: 100);

      final totalEngagement = posts.fold<int>(
        0,
        (sum, post) => sum + post.totalEngagement,
      );

      final avgEngagement = posts.isNotEmpty
          ? totalEngagement / posts.length
          : 0.0;

      return {
        'account': account?.toJson(),
        'postsCount': postsCount,
        'totalEngagement': totalEngagement,
        'averageEngagement': avgEngagement,
        'connectionStatus': await isLinkedInConnected(),
        'lastSyncedAt': account?.lastSyncedAt?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting analytics: $e');
      return {};
    }
  }

  /// Start monitoring data changes
  void startDataMonitoring() {
    if (_isMonitoringData) return;

    debugPrint('🔄 [LINKEDIN SERVICE] Starting data monitoring...');
    _isMonitoringData = true;

    // Initial data load
    _refreshDataStreams();

    // Set up periodic refresh (every 30 minutes due to LinkedIn rate limits)
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      if (!_isMonitoringData) {
        timer.cancel();
        return;
      }

      final isConnected = await isLinkedInConnected();
      if (isConnected) {
        await syncLinkedInData();
      }
    });
  }

  /// Stop monitoring data changes
  void stopDataMonitoring() {
    debugPrint('⏹️ [LINKEDIN SERVICE] Stopping data monitoring...');
    _isMonitoringData = false;
  }

  /// Refresh all data streams
  Future<void> _refreshDataStreams() async {
    try {
      final isConnected = await isLinkedInConnected();
      _connectionController.add(isConnected);

      if (isConnected) {
        final account = await getLinkedInAccount();
        _accountController.add(account);

        final posts = await getPosts();
        _postsController.add(posts);
      } else {
        _accountController.add(null);
        _postsController.add([]);
      }
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error refreshing data streams: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    stopDataMonitoring();
    _accountController.close();
    _postsController.close();
    _connectionController.close();
  }
}
