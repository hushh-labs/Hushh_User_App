import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/linkedin_repository.dart';
import '../../domain/entities/linkedin_account.dart';
import '../../domain/entities/linkedin_post.dart';
import '../../domain/entities/linkedin_connection.dart';
import '../../domain/entities/linkedin_position.dart';
import '../../domain/entities/linkedin_education.dart';
import '../../domain/entities/linkedin_skill.dart';
import '../../domain/entities/linkedin_certification.dart';
import '../../domain/entities/linkedin_message.dart';
import '../../../../core/services/supabase_service.dart';

class LinkedInRepositoryImpl implements LinkedInRepository {
  final SupabaseService _supabaseService;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  LinkedInRepositoryImpl(this._supabaseService);

  @override
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Account Management
  @override
  Future<bool> connectLinkedIn(
    String userId, {
    required String accessToken,
    String? refreshToken,
    required String email,
    required String profileId,
    required List<String> scopes,
    DateTime? tokenExpiresAt,
    String? firstName,
    String? lastName,
    String? profileUrl,
    String? profilePictureUrl,
    String? headline,
    String? industry,
    String? location,
  }) async {
    try {
      await _supabaseService.client.from('linkedin_accounts').upsert({
        'userId': userId,
        'isConnected': true,
        'provider': 'linkedin',
        'email': email,
        'profileId': profileId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'scopes': scopes,
        'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
        'firstName': firstName,
        'lastName': lastName,
        'profileUrl': profileUrl,
        'profilePictureUrl': profilePictureUrl,
        'headline': headline,
        'industry': industry,
        'location': location,
        'connectedAt': DateTime.now().toIso8601String(),
        'lastSyncAt': null,
        'syncSettings': {},
        'updated_at': DateTime.now().toIso8601String(),
      });

      _connectionStatusController.add(true);
      return true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error connecting: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnectLinkedIn(String userId) async {
    try {
      // Delete account data
      await _supabaseService.client
          .from('linkedin_accounts')
          .delete()
          .eq('userId', userId);

      // Clean up related data
      await Future.wait([
        _supabaseService.client
            .from('linkedin_posts')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_connections')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_positions')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_education')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_skills')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_certifications')
            .delete()
            .eq('userId', userId),
        _supabaseService.client
            .from('linkedin_messages')
            .delete()
            .eq('userId', userId),
      ]);

      _connectionStatusController.add(false);
      return true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error disconnecting: $e');
      return false;
    }
  }

  @override
  Future<bool> isLinkedInConnected(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_accounts')
          .select('isConnected')
          .eq('userId', userId)
          .maybeSingle();

      return response?['isConnected'] == true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error checking connection: $e');
      return false;
    }
  }

  @override
  Future<LinkedInAccount?> getLinkedInAccount(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_accounts')
          .select('*')
          .eq('userId', userId)
          .maybeSingle();

      if (response == null) return null;

      return LinkedInAccount(
        userId: response['userId'],
        isConnected: response['isConnected'] ?? false,
        email: response['email'],
        profileId: response['profileId'],
        provider: response['provider'] ?? 'linkedin',
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'],
        scopes: response['scopes']?.cast<String>(),
        tokenExpiresAt: response['tokenExpiresAt'] != null
            ? DateTime.parse(response['tokenExpiresAt'])
            : null,
        firstName: response['firstName'],
        lastName: response['lastName'],
        profileUrl: response['profileUrl'],
        profilePictureUrl: response['profilePictureUrl'],
        headline: response['headline'],
        industry: response['industry'],
        location: response['location'],
        lastSyncAt: response['lastSyncAt'] != null
            ? DateTime.parse(response['lastSyncAt'])
            : null,
        syncSettings: response['syncSettings']?.cast<String, dynamic>(),
        connectedAt: response['connectedAt'] != null
            ? DateTime.parse(response['connectedAt'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting account: $e');
      return null;
    }
  }

  // Placeholder implementations for comprehensive data management
  // These would connect to LinkedIn API via Supabase Edge Functions

  @override
  Future<bool> syncData(String userId, LinkedInSyncOptions syncOptions) async {
    try {
      // Call Supabase Edge Function for comprehensive sync
      final response = await _supabaseService.client.functions.invoke(
        'linkedin-comprehensive-sync',
        body: {'userId': userId, 'syncOptions': syncOptions.toJson()},
      );

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error syncing data: $e');
      return false;
    }
  }

  @override
  Future<bool> syncPosts(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Implementation for posts sync
    return true;
  }

  @override
  Future<bool> syncConnections(String userId) async {
    // Implementation for connections sync
    return true;
  }

  @override
  Future<List<LinkedInPost>> getPosts(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabaseService.client
          .from('linkedin_posts')
          .select('*')
          .eq('userId', userId)
          .order('publishedAt', ascending: false);

      if (limit != null) query = query.limit(limit);
      if (offset != null)
        query = query.range(offset, offset + (limit ?? 10) - 1);

      final response = await query;

      return (response as List)
          .map(
            (data) => LinkedInPost(
              id: data['id'],
              userId: data['userId'],
              postId: data['postId'],
              authorId: data['authorId'],
              authorName: data['authorName'],
              text: data['text'],
              publishedAt: DateTime.parse(data['publishedAt']),
              likesCount: data['likesCount'] ?? 0,
              commentsCount: data['commentsCount'] ?? 0,
              sharesCount: data['sharesCount'] ?? 0,
              syncedAt: data['syncedAt'] != null
                  ? DateTime.parse(data['syncedAt'])
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting posts: $e');
      return [];
    }
  }

  @override
  Future<List<LinkedInConnection>> getConnections(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    try {
      var query = _supabaseService.client
          .from('linkedin_connections')
          .select('*')
          .eq('userId', userId)
          .order('connectedAt', ascending: false);

      if (limit != null) query = query.limit(limit);
      if (offset != null)
        query = query.range(offset, offset + (limit ?? 10) - 1);

      final response = await query;

      return (response as List)
          .map(
            (data) => LinkedInConnection(
              id: data['id'],
              userId: data['userId'],
              connectionId: data['connectionId'],
              firstName: data['firstName'],
              lastName: data['lastName'],
              email: data['email'],
              profileUrl: data['profileUrl'],
              headline: data['headline'],
              companyName: data['currentCompanyName'],
              position: data['currentPosition'],
              connectedAt: data['connectedAt'] != null
                  ? DateTime.parse(data['connectedAt'])
                  : null,
              syncedAt: data['syncedAt'] != null
                  ? DateTime.parse(data['syncedAt'])
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting connections: $e');
      return [];
    }
  }

  // Professional Experience Methods
  @override
  Future<List<LinkedInPosition>> getPositions(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_positions')
          .select('*')
          .eq('userId', userId)
          .order('startDate', ascending: false);

      return (response as List)
          .map(
            (data) => LinkedInPosition(
              id: data['id'],
              userId: data['userId'],
              positionId: data['positionId'],
              title: data['title'],
              companyName: data['companyName'],
              isCurrent: data['isCurrent'] ?? false,
              startDate: data['startDate'] != null
                  ? DateTime.parse(data['startDate'])
                  : null,
              endDate: data['endDate'] != null
                  ? DateTime.parse(data['endDate'])
                  : null,
              syncedAt: data['syncedAt'] != null
                  ? DateTime.parse(data['syncedAt'])
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting positions: $e');
      return [];
    }
  }

  @override
  Future<LinkedInPosition?> getCurrentPosition(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_positions')
          .select('*')
          .eq('userId', userId)
          .eq('isCurrent', true)
          .order('startDate', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return LinkedInPosition(
        id: response['id'],
        userId: response['userId'],
        positionId: response['positionId'],
        title: response['title'],
        companyName: response['companyName'],
        isCurrent: response['isCurrent'] ?? false,
        startDate: response['startDate'] != null
            ? DateTime.parse(response['startDate'])
            : null,
        endDate: response['endDate'] != null
            ? DateTime.parse(response['endDate'])
            : null,
        syncedAt: response['syncedAt'] != null
            ? DateTime.parse(response['syncedAt'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting current position: $e');
      return null;
    }
  }

  // Placeholder implementations for all other methods
  // Add similar implementations for education, skills, certifications, etc.

  @override
  Future<bool> syncPositions(String userId) async => true;

  @override
  Future<int> getPositionsCount(String userId) async => 0;

  @override
  Future<List<LinkedInEducation>> getEducation(String userId) async => [];

  @override
  Future<bool> syncEducation(String userId) async => true;

  @override
  Future<int> getEducationCount(String userId) async => 0;

  @override
  Future<List<LinkedInSkill>> getSkills(
    String userId, {
    String? category,
  }) async => [];

  @override
  Future<bool> syncSkills(String userId) async => true;

  @override
  Future<int> getSkillsCount(String userId) async => 0;

  @override
  Future<List<LinkedInSkill>> getTopSkills(
    String userId, {
    int limit = 10,
  }) async => [];

  @override
  Future<List<LinkedInCertification>> getCertifications(String userId) async =>
      [];

  @override
  Future<bool> syncCertifications(String userId) async => true;

  @override
  Future<int> getCertificationsCount(String userId) async => 0;

  @override
  Future<List<LinkedInCertification>> getValidCertifications(
    String userId,
  ) async => [];

  @override
  Future<List<LinkedInMessage>> getMessages(
    String userId, {
    String? conversationId,
    int? limit,
    int? offset,
    bool unreadOnly = false,
  }) async => [];

  @override
  Future<bool> syncMessages(String userId, {DateTime? fromDate}) async => true;

  @override
  Future<int> getMessagesCount(
    String userId, {
    bool unreadOnly = false,
  }) async => 0;

  @override
  Future<int> getConversationsCount(String userId) async => 0;

  @override
  Future<LinkedInSyncOptions?> getSyncSettings(String userId) async => null;

  @override
  Future<bool> updateSyncSettings(
    String userId,
    LinkedInSyncOptions syncOptions,
  ) async => true;

  @override
  Future<DateTime?> getLastSyncDate(String userId) async => null;

  @override
  Future<bool> refreshAccessToken(String userId) async => true;

  @override
  Future<bool> updateTokens(
    String userId, {
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async => true;

  @override
  Future<Map<String, dynamic>> getProfileAnalytics(String userId) async => {};

  @override
  Future<Map<String, dynamic>> getNetworkInsights(String userId) async => {};

  @override
  Future<Map<String, dynamic>> getSkillsAnalytics(String userId) async => {};

  @override
  Future<Map<String, dynamic>> getEngagementMetrics(String userId) async => {};

  @override
  Future<Map<String, dynamic>> exportAllData(String userId) async => {};

  @override
  Future<bool> deleteAllData(String userId) async => true;

  @override
  Future<bool> deleteOldData(String userId, DateTime beforeDate) async => true;

  @override
  Future<List<dynamic>> searchAllData(
    String userId,
    String query, {
    List<String>? dataTypes,
    int? limit,
  }) async => [];

  @override
  Future<bool> bulkSyncData(String userId, LinkedInSyncOptions options) async =>
      true;

  @override
  Future<bool> refreshAllTokens() async => true;

  // Stream implementations
  @override
  Stream<List<LinkedInPost>> getPostsStream(String userId) => Stream.periodic(
    Duration(minutes: 5),
    (_) => [],
  ).asyncMap((_) => getPosts(userId));

  @override
  Stream<List<LinkedInConnection>> getConnectionsStream(String userId) =>
      Stream.periodic(
        Duration(minutes: 10),
        (_) => [],
      ).asyncMap((_) => getConnections(userId));

  @override
  Stream<List<LinkedInPosition>> getPositionsStream(String userId) =>
      Stream.periodic(
        Duration(hours: 1),
        (_) => [],
      ).asyncMap((_) => getPositions(userId));

  @override
  Stream<List<LinkedInEducation>> getEducationStream(String userId) =>
      Stream.periodic(
        Duration(hours: 1),
        (_) => [],
      ).asyncMap((_) => getEducation(userId));

  @override
  Stream<List<LinkedInSkill>> getSkillsStream(String userId) => Stream.periodic(
    Duration(hours: 1),
    (_) => [],
  ).asyncMap((_) => getSkills(userId));

  @override
  Stream<List<LinkedInCertification>> getCertificationsStream(String userId) =>
      Stream.periodic(
        Duration(hours: 1),
        (_) => [],
      ).asyncMap((_) => getCertifications(userId));

  @override
  Stream<List<LinkedInMessage>> getMessagesStream(String userId) =>
      Stream.periodic(
        Duration(minutes: 2),
        (_) => [],
      ).asyncMap((_) => getMessages(userId));

  @override
  Future<int> getPostsCount(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_posts')
          .select('id')
          .eq('userId', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> deleteOldPosts(String userId, DateTime beforeDate) async {
    try {
      await _supabaseService.client
          .from('linkedin_posts')
          .delete()
          .eq('userId', userId)
          .lt('publishedAt', beforeDate.toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getConnectionsCount(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_connections')
          .select('id')
          .eq('userId', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<LinkedInConnection?> getConnection(
    String userId,
    String connectionId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('linkedin_connections')
          .select('*')
          .eq('userId', userId)
          .eq('connectionId', connectionId)
          .maybeSingle();

      if (response == null) return null;

      return LinkedInConnection(
        id: response['id'],
        userId: response['userId'],
        connectionId: response['connectionId'],
        firstName: response['firstName'],
        lastName: response['lastName'],
        email: response['email'],
        profileUrl: response['profileUrl'],
        headline: response['headline'],
        companyName: response['currentCompanyName'],
        position: response['currentPosition'],
        connectedAt: response['connectedAt'] != null
            ? DateTime.parse(response['connectedAt'])
            : null,
        syncedAt: response['syncedAt'] != null
            ? DateTime.parse(response['syncedAt'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting connection: $e');
      return null;
    }
  }
}
