import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/simple_linkedin_account.dart';
import '../../domain/entities/simple_linkedin_post.dart';
import '../../domain/repositories/simple_linkedin_repository.dart';
import '../services/simple_linkedin_service.dart';
import '../../../../core/services/supabase_service.dart';

class SimpleLinkedInRepositoryImpl implements SimpleLinkedInRepository {
  final SupabaseService _supabaseService;

  SimpleLinkedInRepositoryImpl(this._supabaseService);

  SupabaseClient get _supabase => _supabaseService.client;

  @override
  Future<bool> isLinkedInConnected(String userId) async {
    try {
      final response = await _supabase
          .from('linkedin_accounts')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error checking connection: $e');
      return false;
    }
  }

  @override
  Future<LinkedInAccount?> getLinkedInAccount(String userId) async {
    try {
      final response = await _supabase
          .from('linkedin_accounts')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return LinkedInAccount.fromJson(response);
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting LinkedIn account: $e');
      return null;
    }
  }

  @override
  Future<bool> disconnectLinkedIn(String userId) async {
    try {
      // Mark account as inactive instead of deleting
      await _supabase
          .from('linkedin_accounts')
          .update({
            'is_active': false,
            'access_token': null,
            'refresh_token': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error disconnecting LinkedIn: $e');
      return false;
    }
  }

  @override
  Future<bool> syncData(String userId, LinkedInSyncOptions options) async {
    try {
      // This is a placeholder - actual sync would happen via Edge Function
      // The Edge Function would call LinkedIn API and populate our tables

      // For now, we'll just update the last_synced_at timestamp
      await _supabase
          .from('linkedin_accounts')
          .update({'last_synced_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_active', true);

      debugPrint('🔄 [LINKEDIN REPO] Sync triggered for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error syncing data: $e');
      return false;
    }
  }

  @override
  Future<List<LinkedInPost>> getPosts(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('linkedin_posts')
          .select('*')
          .eq('user_id', userId)
          .order('posted_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => LinkedInPost.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting posts: $e');
      return [];
    }
  }

  @override
  Future<int> getPostsCount(String userId) async {
    try {
      final response = await _supabase
          .from('linkedin_posts')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting posts count: $e');
      return 0;
    }
  }

  @override
  Future<List<LinkedInPost>> searchPosts(String userId, String query) async {
    try {
      final response = await _supabase
          .from('linkedin_posts')
          .select('*')
          .eq('user_id', userId)
          .textSearch('content', query)
          .order('posted_at', ascending: false);

      return (response as List)
          .map((json) => LinkedInPost.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error searching posts: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getBasicAnalytics(String userId) async {
    try {
      // Get account info
      final account = await getLinkedInAccount(userId);

      // Get posts count and basic metrics
      final postsCount = await getPostsCount(userId);
      final posts = await getPosts(userId, limit: 100);

      final totalEngagement = posts.fold<int>(
        0,
        (sum, post) => sum + post.totalEngagement,
      );

      final avgEngagement = posts.isNotEmpty
          ? totalEngagement / posts.length
          : 0.0;

      // Basic post type distribution
      final postTypeDistribution = <String, int>{};
      for (final post in posts) {
        final type = post.postType ?? 'post';
        postTypeDistribution[type] = (postTypeDistribution[type] ?? 0) + 1;
      }

      return {
        'account': account?.toJson(),
        'postsCount': postsCount,
        'totalEngagement': totalEngagement,
        'averageEngagement': avgEngagement,
        'postTypeDistribution': postTypeDistribution,
        'connectionStatus': account != null,
        'lastSyncedAt': account?.lastSyncedAt?.toIso8601String(),
        'connectedAt': account?.connectedAt.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ [LINKEDIN REPO] Error getting analytics: $e');
      return {};
    }
  }
}
