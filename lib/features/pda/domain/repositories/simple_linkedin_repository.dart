import '../entities/simple_linkedin_account.dart';
import '../entities/simple_linkedin_post.dart';
import '../../data/services/simple_linkedin_service.dart';

abstract class SimpleLinkedInRepository {
  // Connection management
  Future<bool> isLinkedInConnected(String userId);
  Future<LinkedInAccount?> getLinkedInAccount(String userId);
  Future<bool> disconnectLinkedIn(String userId);

  // Data synchronization
  Future<bool> syncData(String userId, LinkedInSyncOptions options);

  // Posts
  Future<List<LinkedInPost>> getPosts(
    String userId, {
    int limit = 50,
    int offset = 0,
  });
  Future<int> getPostsCount(String userId);
  Future<List<LinkedInPost>> searchPosts(String userId, String query);

  // Analytics (basic)
  Future<Map<String, dynamic>> getBasicAnalytics(String userId);
}
