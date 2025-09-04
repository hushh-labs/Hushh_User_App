import '../entities/linkedin_account.dart';
import '../entities/linkedin_post.dart';
import '../entities/linkedin_connection.dart';
import '../entities/linkedin_position.dart';
import '../entities/linkedin_education.dart';
import '../entities/linkedin_skill.dart';
import '../entities/linkedin_certification.dart';
import '../entities/linkedin_message.dart';

/// Options for syncing LinkedIn data
class LinkedInSyncOptions {
  final bool includePosts;
  final bool includeConnections;
  final bool includeProfile;
  final bool includePositions;
  final bool includeEducation;
  final bool includeSkills;
  final bool includeCertifications;
  final bool includeMessages;
  final int durationDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LinkedInSyncOptions({
    this.includePosts = true,
    this.includeConnections = true,
    this.includeProfile = true,
    this.includePositions = true,
    this.includeEducation = true,
    this.includeSkills = true,
    this.includeCertifications = true,
    this.includeMessages = false, // Default false due to privacy
    this.durationDays = 30,
    this.customStartDate,
    this.customEndDate,
  });

  LinkedInSyncOptions copyWith({
    bool? includePosts,
    bool? includeConnections,
    bool? includeProfile,
    bool? includePositions,
    bool? includeEducation,
    bool? includeSkills,
    bool? includeCertifications,
    bool? includeMessages,
    int? durationDays,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return LinkedInSyncOptions(
      includePosts: includePosts ?? this.includePosts,
      includeConnections: includeConnections ?? this.includeConnections,
      includeProfile: includeProfile ?? this.includeProfile,
      includePositions: includePositions ?? this.includePositions,
      includeEducation: includeEducation ?? this.includeEducation,
      includeSkills: includeSkills ?? this.includeSkills,
      includeCertifications:
          includeCertifications ?? this.includeCertifications,
      includeMessages: includeMessages ?? this.includeMessages,
      durationDays: durationDays ?? this.durationDays,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includePosts': includePosts,
      'includeConnections': includeConnections,
      'includeProfile': includeProfile,
      'includePositions': includePositions,
      'includeEducation': includeEducation,
      'includeSkills': includeSkills,
      'includeCertifications': includeCertifications,
      'includeMessages': includeMessages,
      'durationDays': durationDays,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
    };
  }

  factory LinkedInSyncOptions.fromJson(Map<String, dynamic> json) {
    return LinkedInSyncOptions(
      includePosts: json['includePosts'] ?? true,
      includeConnections: json['includeConnections'] ?? true,
      includeProfile: json['includeProfile'] ?? true,
      includePositions: json['includePositions'] ?? true,
      includeEducation: json['includeEducation'] ?? true,
      includeSkills: json['includeSkills'] ?? true,
      includeCertifications: json['includeCertifications'] ?? true,
      includeMessages: json['includeMessages'] ?? false,
      durationDays: json['durationDays'] ?? 30,
      customStartDate: json['customStartDate'] != null
          ? DateTime.parse(json['customStartDate'])
          : null,
      customEndDate: json['customEndDate'] != null
          ? DateTime.parse(json['customEndDate'])
          : null,
    );
  }
}

abstract class LinkedInRepository {
  // Account Management
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
  });

  Future<bool> disconnectLinkedIn(String userId);
  Future<bool> isLinkedInConnected(String userId);
  Future<LinkedInAccount?> getLinkedInAccount(String userId);

  // Data Sync
  Future<bool> syncData(String userId, LinkedInSyncOptions syncOptions);
  Future<bool> syncPosts(String userId, {DateTime? fromDate, DateTime? toDate});
  Future<bool> syncConnections(String userId);

  // Posts Management
  Future<List<LinkedInPost>> getPosts(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  });
  Future<int> getPostsCount(String userId);
  Future<bool> deleteOldPosts(String userId, DateTime beforeDate);

  // Connections Management
  Future<List<LinkedInConnection>> getConnections(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
  });
  Future<int> getConnectionsCount(String userId);
  Future<LinkedInConnection?> getConnection(String userId, String connectionId);

  // Sync Settings
  Future<bool> updateSyncSettings(
    String userId,
    LinkedInSyncOptions syncOptions,
  );
  Future<LinkedInSyncOptions?> getSyncSettings(String userId);
  Future<DateTime?> getLastSyncDate(String userId);

  // Token Management
  Future<bool> refreshAccessToken(String userId);
  Future<bool> updateTokens(
    String userId, {
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  });

  // Professional Experience Management
  Future<List<LinkedInPosition>> getPositions(String userId);
  Future<bool> syncPositions(String userId);
  Future<int> getPositionsCount(String userId);
  Future<LinkedInPosition?> getCurrentPosition(String userId);

  // Education Management
  Future<List<LinkedInEducation>> getEducation(String userId);
  Future<bool> syncEducation(String userId);
  Future<int> getEducationCount(String userId);

  // Skills Management
  Future<List<LinkedInSkill>> getSkills(String userId, {String? category});
  Future<bool> syncSkills(String userId);
  Future<int> getSkillsCount(String userId);
  Future<List<LinkedInSkill>> getTopSkills(String userId, {int limit = 10});

  // Certifications Management
  Future<List<LinkedInCertification>> getCertifications(String userId);
  Future<bool> syncCertifications(String userId);
  Future<int> getCertificationsCount(String userId);
  Future<List<LinkedInCertification>> getValidCertifications(String userId);

  // Messages Management
  Future<List<LinkedInMessage>> getMessages(
    String userId, {
    String? conversationId,
    int? limit,
    int? offset,
    bool unreadOnly = false,
  });
  Future<bool> syncMessages(String userId, {DateTime? fromDate});
  Future<int> getMessagesCount(String userId, {bool unreadOnly = false});
  Future<int> getConversationsCount(String userId);

  // Advanced Analytics and Insights
  Future<Map<String, dynamic>> getProfileAnalytics(String userId);
  Future<Map<String, dynamic>> getNetworkInsights(String userId);
  Future<Map<String, dynamic>> getSkillsAnalytics(String userId);
  Future<Map<String, dynamic>> getEngagementMetrics(String userId);

  // Data Export and Management
  Future<Map<String, dynamic>> exportAllData(String userId);
  Future<bool> deleteAllData(String userId);
  Future<bool> deleteOldData(String userId, DateTime beforeDate);

  // Comprehensive Search
  Future<List<dynamic>> searchAllData(
    String userId,
    String query, {
    List<String>? dataTypes, // ['posts', 'connections', 'positions', etc.]
    int? limit,
  });

  // Bulk Operations
  Future<bool> bulkSyncData(String userId, LinkedInSyncOptions options);
  Future<bool> refreshAllTokens();

  // Streams for real-time updates
  Stream<bool> get connectionStatusStream;
  Stream<List<LinkedInPost>> getPostsStream(String userId);
  Stream<List<LinkedInConnection>> getConnectionsStream(String userId);
  Stream<List<LinkedInPosition>> getPositionsStream(String userId);
  Stream<List<LinkedInEducation>> getEducationStream(String userId);
  Stream<List<LinkedInSkill>> getSkillsStream(String userId);
  Stream<List<LinkedInCertification>> getCertificationsStream(String userId);
  Stream<List<LinkedInMessage>> getMessagesStream(String userId);
}
