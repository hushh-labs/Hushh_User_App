import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/repositories/linkedin_repository.dart';
import '../../domain/entities/linkedin_account.dart';
import '../../domain/entities/linkedin_post.dart';
import '../../domain/entities/linkedin_connection.dart';
import '../../domain/entities/linkedin_position.dart';
import '../../domain/entities/linkedin_education.dart';
import '../../domain/entities/linkedin_skill.dart';
import '../../domain/entities/linkedin_certification.dart';
import '../../domain/entities/linkedin_message.dart';
import 'linkedin_context_prewarm_service.dart';

/// Result class for LinkedIn operations
class LinkedInConnectionResult {
  final bool isSuccess;
  final String? error;
  final int? postsCount;
  final int? connectionsCount;

  LinkedInConnectionResult._({
    required this.isSuccess,
    this.error,
    this.postsCount,
    this.connectionsCount,
  });

  factory LinkedInConnectionResult.success({
    int? postsCount,
    int? connectionsCount,
  }) {
    return LinkedInConnectionResult._(
      isSuccess: true,
      postsCount: postsCount,
      connectionsCount: connectionsCount,
    );
  }

  factory LinkedInConnectionResult.failure(String error) {
    return LinkedInConnectionResult._(isSuccess: false, error: error);
  }
}

/// Service to handle LinkedIn OAuth connection and management with Supabase
class SupabaseLinkedInService {
  static final SupabaseLinkedInService _instance =
      SupabaseLinkedInService._internal();
  factory SupabaseLinkedInService() => _instance;
  SupabaseLinkedInService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  final LinkedInContextPrewarmService _prewarmService =
      LinkedInContextPrewarmService();

  // Stream controllers for real-time updates
  final StreamController<List<LinkedInPost>> _postsController =
      StreamController<List<LinkedInPost>>.broadcast();
  final StreamController<List<LinkedInConnection>> _connectionsController =
      StreamController<List<LinkedInConnection>>.broadcast();
  final StreamController<List<LinkedInPosition>> _positionsController =
      StreamController<List<LinkedInPosition>>.broadcast();
  final StreamController<List<LinkedInEducation>> _educationController =
      StreamController<List<LinkedInEducation>>.broadcast();
  final StreamController<List<LinkedInSkill>> _skillsController =
      StreamController<List<LinkedInSkill>>.broadcast();
  final StreamController<List<LinkedInCertification>>
  _certificationsController =
      StreamController<List<LinkedInCertification>>.broadcast();
  final StreamController<List<LinkedInMessage>> _messagesController =
      StreamController<List<LinkedInMessage>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isMonitoringData = false;

  // Lazy getters for dependencies
  LinkedInRepository get _repository {
    try {
      return _getIt<LinkedInRepository>();
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Repository not found in GetIt: $e');
      throw Exception(
        'LinkedInRepository not registered. Make sure LinkedInModule.register() is called.',
      );
    }
  }

  // LinkedIn OAuth configuration
  String get _linkedInClientId {
    // Hardcoded for now to bypass .env parsing issues
    return '86bxfdosvae3t6';
  }

  String get _linkedInRedirectUri {
    // Hardcoded for now
    return 'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/linkedin-simple-sync';
  }

  /// Check if LinkedIn is connected for the current user
  Future<bool> isLinkedInConnected() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await _repository.isLinkedInConnected(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error checking connection status: $e');
      return false;
    }
  }

  /// Stream to listen to LinkedIn connection status changes
  Stream<bool> get linkedInConnectionStream => _connectionController.stream;

  /// Stream to listen to posts updates
  Stream<List<LinkedInPost>> get postsStream => _postsController.stream;

  /// Stream to listen to connections updates
  Stream<List<LinkedInConnection>> get connectionsStream =>
      _connectionsController.stream;

  /// Stream to listen to positions updates
  Stream<List<LinkedInPosition>> get positionsStream =>
      _positionsController.stream;

  /// Stream to listen to education updates
  Stream<List<LinkedInEducation>> get educationStream =>
      _educationController.stream;

  /// Stream to listen to skills updates
  Stream<List<LinkedInSkill>> get skillsStream => _skillsController.stream;

  /// Stream to listen to certifications updates
  Stream<List<LinkedInCertification>> get certificationsStream =>
      _certificationsController.stream;

  /// Stream to listen to messages updates
  Stream<List<LinkedInMessage>> get messagesStream =>
      _messagesController.stream;

  /// Connect LinkedIn account by performing OAuth flow
  Future<LinkedInConnectionResult> connectLinkedIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return LinkedInConnectionResult.failure('User not authenticated');
      }

      debugPrint('🔐 [LINKEDIN SERVICE] Starting LinkedIn OAuth flow...');

      // Generate OAuth URL and launch browser
      final authUrl = _generateLinkedInAuthUrl();
      debugPrint('🔐 [LINKEDIN SERVICE] Auth URL: $authUrl');

      // Launch the OAuth URL in external browser
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        final result = await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );

        debugPrint('🔐 [LINKEDIN SERVICE] External browser launched: $result');

        // Give user time to complete the OAuth flow in external browser
        // The OAuth will redirect to our Edge function which handles token exchange
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

            // Pre-warm PDA with LinkedIn context after successful connection
            _prewarmService.prewarmLinkedInContext();

            return LinkedInConnectionResult.success();
          }
          // Wait a bit more before checking again
          await Future.delayed(const Duration(seconds: 2));
        }

        return LinkedInConnectionResult.failure(
          'OAuth completed but connection not detected. Please try again.',
        );
      } else {
        return LinkedInConnectionResult.failure('Could not launch OAuth URL');
      }
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error during OAuth: $e');
      return LinkedInConnectionResult.failure('OAuth failed: $e');
    }
  }

  /// Generate LinkedIn OAuth authorization URL
  String _generateLinkedInAuthUrl() {
    // Enhanced scopes for comprehensive data access with Share on LinkedIn product
    final scopes = [
      'openid',
      'profile',
      'email',
      'w_member_social', // Share on LinkedIn - allows posting and reading social content
    ].join(' ');
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final params = {
      'response_type': 'code',
      'client_id': _linkedInClientId,
      'redirect_uri': _linkedInRedirectUri,
      'state': state,
      'scope': scopes,
    };

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'https://www.linkedin.com/oauth/v2/authorization?$queryString';
  }

  /// Get LinkedIn account information
  Future<LinkedInAccount?> getLinkedInAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await _repository.getLinkedInAccount(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting account: $e');
      return null;
    }
  }

  /// Sync LinkedIn data
  Future<LinkedInConnectionResult> syncLinkedInData(
    LinkedInSyncOptions syncOptions,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return LinkedInConnectionResult.failure('User not authenticated');
      }

      debugPrint('🔄 [LINKEDIN SERVICE] Starting LinkedIn data sync...');

      // Check if LinkedIn is connected
      final isConnected = await isLinkedInConnected();
      if (!isConnected) {
        return LinkedInConnectionResult.failure('LinkedIn not connected');
      }

      // Call the sync function via Supabase Edge Function
      final success = await _repository.syncData(user.uid, syncOptions);

      if (success) {
        // Update connection status
        _connectionController.add(true);

        // Refresh data streams
        await _refreshDataStreams();

        // Pre-warm PDA with updated LinkedIn context after sync
        _prewarmService.prewarmLinkedInContext();

        debugPrint('✅ [LINKEDIN SERVICE] Data sync completed successfully');
        return LinkedInConnectionResult.success();
      } else {
        return LinkedInConnectionResult.failure('Sync failed');
      }
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error during sync: $e');
      return LinkedInConnectionResult.failure('Sync error: $e');
    }
  }

  /// Refresh data streams with latest LinkedIn data
  Future<void> _refreshDataStreams() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Refresh posts
      final posts = await _repository.getPosts(user.uid, limit: 50);
      _postsController.add(posts);

      // Refresh connections
      final connections = await _repository.getConnections(
        user.uid,
        limit: 100,
      );
      _connectionsController.add(connections);

      // Refresh positions
      final positions = await _repository.getPositions(user.uid);
      _positionsController.add(positions);

      // Refresh education
      final education = await _repository.getEducation(user.uid);
      _educationController.add(education);

      // Refresh skills
      final skills = await _repository.getSkills(user.uid);
      _skillsController.add(skills);

      // Refresh certifications
      final certifications = await _repository.getCertifications(user.uid);
      _certificationsController.add(certifications);

      // Refresh messages (only recent ones for privacy)
      final messages = await _repository.getMessages(user.uid, limit: 20);
      _messagesController.add(messages);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error refreshing streams: $e');
    }
  }

  /// Get LinkedIn posts
  Future<List<LinkedInPost>> getPosts({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getPosts(
        user.uid,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting posts: $e');
      return [];
    }
  }

  /// Get LinkedIn connections
  Future<List<LinkedInConnection>> getConnections({
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getConnections(
        user.uid,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting connections: $e');
      return [];
    }
  }

  /// Get LinkedIn positions/work experience
  Future<List<LinkedInPosition>> getPositions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getPositions(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting positions: $e');
      return [];
    }
  }

  /// Get current position
  Future<LinkedInPosition?> getCurrentPosition() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await _repository.getCurrentPosition(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting current position: $e');
      return null;
    }
  }

  /// Get LinkedIn education
  Future<List<LinkedInEducation>> getEducation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getEducation(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting education: $e');
      return [];
    }
  }

  /// Get LinkedIn skills
  Future<List<LinkedInSkill>> getSkills({String? category}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getSkills(user.uid, category: category);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting skills: $e');
      return [];
    }
  }

  /// Get top skills
  Future<List<LinkedInSkill>> getTopSkills({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getTopSkills(user.uid, limit: limit);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting top skills: $e');
      return [];
    }
  }

  /// Get LinkedIn certifications
  Future<List<LinkedInCertification>> getCertifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getCertifications(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting certifications: $e');
      return [];
    }
  }

  /// Get valid certifications only
  Future<List<LinkedInCertification>> getValidCertifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getValidCertifications(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting valid certifications: $e');
      return [];
    }
  }

  /// Get LinkedIn messages
  Future<List<LinkedInMessage>> getMessages({
    String? conversationId,
    int? limit,
    int? offset,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.getMessages(
        user.uid,
        conversationId: conversationId,
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting messages: $e');
      return [];
    }
  }

  /// Get comprehensive profile analytics
  Future<Map<String, dynamic>> getProfileAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      return await _repository.getProfileAnalytics(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting profile analytics: $e');
      return {};
    }
  }

  /// Get network insights
  Future<Map<String, dynamic>> getNetworkInsights() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      return await _repository.getNetworkInsights(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting network insights: $e');
      return {};
    }
  }

  /// Search across all LinkedIn data
  Future<List<dynamic>> searchAllData(
    String query, {
    List<String>? dataTypes,
    int? limit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _repository.searchAllData(
        user.uid,
        query,
        dataTypes: dataTypes,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error searching data: $e');
      return [];
    }
  }

  /// Export all LinkedIn data
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      return await _repository.exportAllData(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error exporting data: $e');
      return {};
    }
  }

  /// Disconnect LinkedIn account
  Future<bool> disconnectLinkedIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      debugPrint('🔌 [LINKEDIN SERVICE] Disconnecting LinkedIn account...');

      final result = await _repository.disconnectLinkedIn(user.uid);

      if (result) {
        // Update connection status
        _connectionController.add(false);

        // Clear data streams
        _postsController.add([]);
        _connectionsController.add([]);
        _positionsController.add([]);
        _educationController.add([]);
        _skillsController.add([]);
        _certificationsController.add([]);
        _messagesController.add([]);

        // Clear LinkedIn context cache when disconnected
        _prewarmService.clearLinkedInContextCache();

        debugPrint('✅ [LINKEDIN SERVICE] LinkedIn disconnected successfully');
      }

      return result;
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error disconnecting LinkedIn: $e');
      return false;
    }
  }

  /// Start monitoring LinkedIn data for real-time updates
  void startMonitoring() {
    if (_isMonitoringData) return;

    debugPrint('👁️ [LINKEDIN SERVICE] Starting LinkedIn data monitoring...');
    _isMonitoringData = true;

    // Set up periodic refresh (every 30 minutes due to LinkedIn rate limits)
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      if (!_isMonitoringData) {
        timer.cancel();
        return;
      }

      try {
        final isConnected = await isLinkedInConnected();
        _connectionController.add(isConnected);

        if (isConnected) {
          await _refreshDataStreams();
        }
      } catch (e) {
        debugPrint('❌ [LINKEDIN SERVICE] Error during monitoring: $e');
      }
    });
  }

  /// Stop monitoring LinkedIn data
  void stopMonitoring() {
    debugPrint('🛑 [LINKEDIN SERVICE] Stopping LinkedIn data monitoring...');
    _isMonitoringData = false;
  }

  /// Get sync settings
  Future<LinkedInSyncOptions?> getSyncSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await _repository.getSyncSettings(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting sync settings: $e');
      return null;
    }
  }

  /// Update sync settings
  Future<bool> updateSyncSettings(LinkedInSyncOptions syncOptions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await _repository.updateSyncSettings(user.uid, syncOptions);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error updating sync settings: $e');
      return false;
    }
  }

  /// Get last sync date
  Future<DateTime?> getLastSyncDate() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await _repository.getLastSyncDate(user.uid);
    } catch (e) {
      debugPrint('❌ [LINKEDIN SERVICE] Error getting last sync date: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 [LINKEDIN SERVICE] Disposing resources...');
    stopMonitoring();
    _postsController.close();
    _connectionsController.close();
    _positionsController.close();
    _educationController.close();
    _skillsController.close();
    _certificationsController.close();
    _messagesController.close();
    _connectionController.close();
  }
}
