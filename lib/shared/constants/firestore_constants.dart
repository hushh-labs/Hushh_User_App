// Firestore collections and subcollections constants
class FirestoreCollections {
  // Main collections
  static const String users = 'HushUsers';
  static const String auth = 'auth';
  static const String profiles = 'profiles';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
  static const String messages = 'messages';
  static const String chats = 'chats';
  static const String posts = 'posts';
  static const String comments = 'comments';
  static const String likes = 'likes';
  static const String follows = 'follows';
  static const String reports = 'reports';
  static const String analytics = 'analytics';
  static const String logs = 'logs';

  // Subcollections
  static const String userPosts = 'posts';
  static const String userFollowers = 'followers';
  static const String userFollowing = 'following';
  static const String userSettings = 'settings';
  static const String userNotifications = 'notifications';
  static const String userMessages = 'messages';
  static const String userChats = 'chats';
  static const String userReports = 'reports';
  static const String userAnalytics = 'analytics';
  static const String userLogs = 'logs';

  // Post subcollections
  static const String postComments = 'comments';
  static const String postLikes = 'likes';
  static const String postShares = 'shares';
  static const String postReports = 'reports';

  // Chat subcollections
  static const String chatMessages = 'messages';
  static const String chatParticipants = 'participants';
  static const String chatSettings = 'settings';

  // Comment subcollections
  static const String commentLikes = 'likes';
  static const String commentReplies = 'replies';
  static const String commentReports = 'reports';
}

// Firestore document field names
class FirestoreFields {
  // Common fields
  static const String id = 'id';
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String deletedAt = 'deletedAt';
  static const String isActive = 'isActive';
  static const String isDeleted = 'isDeleted';

  // User fields
  static const String email = 'email';
  static const String name = 'name';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String displayName = 'displayName';
  static const String photoUrl = 'photoUrl';
  static const String phoneNumber = 'phoneNumber';
  static const String dateOfBirth = 'dateOfBirth';
  static const String gender = 'gender';
  static const String bio = 'bio';
  static const String location = 'location';
  static const String website = 'website';
  static const String socialLinks = 'socialLinks';
  static const String preferences = 'preferences';
  static const String settings = 'settings';
  static const String lastSeen = 'lastSeen';
  static const String isOnline = 'isOnline';
  static const String isVerified = 'isVerified';
  static const String isPrivate = 'isPrivate';
  static const String followerCount = 'followerCount';
  static const String followingCount = 'followingCount';
  static const String postCount = 'postCount';

  // Auth fields
  static const String authProvider = 'authProvider';
  static const String emailVerified = 'emailVerified';
  static const String phoneVerified = 'phoneVerified';
  static const String lastLoginAt = 'lastLoginAt';
  static const String loginCount = 'loginCount';
  static const String failedLoginAttempts = 'failedLoginAttempts';
  static const String lockedUntil = 'lockedUntil';
  static const String passwordChangedAt = 'passwordChangedAt';
  static const String passwordResetToken = 'passwordResetToken';
  static const String passwordResetExpires = 'passwordResetExpires';

  // Post fields
  static const String postTitle = 'title';
  static const String content = 'content';
  static const String mediaUrls = 'mediaUrls';
  static const String mediaType = 'mediaType';
  static const String tags = 'tags';
  static const String category = 'category';
  static const String postLocation = 'location';
  static const String isPublic = 'isPublic';
  static const String postIsEdited = 'isEdited';
  static const String postEditedAt = 'editedAt';
  static const String postLikeCount = 'likeCount';
  static const String commentCount = 'commentCount';
  static const String shareCount = 'shareCount';
  static const String viewCount = 'viewCount';

  // Comment fields
  static const String postId = 'postId';
  static const String parentCommentId = 'parentCommentId';
  static const String text = 'text';
  static const String commentLikeCount = 'likeCount';
  static const String replyCount = 'replyCount';

  // Message fields
  static const String chatId = 'chatId';
  static const String senderId = 'senderId';
  static const String receiverId = 'receiverId';
  static const String message = 'message';
  static const String messageType = 'messageType';
  static const String mediaUrl = 'mediaUrl';
  static const String messageIsRead = 'isRead';
  static const String messageReadAt = 'readAt';
  static const String messageIsEdited = 'isEdited';
  static const String messageEditedAt = 'editedAt';
  static const String messageIsDeleted = 'isDeleted';
  static const String messageDeletedAt = 'deletedAt';

  // Notification fields
  static const String type = 'type';
  static const String notificationTitle = 'title';
  static const String body = 'body';
  static const String data = 'data';
  static const String notificationIsRead = 'isRead';
  static const String notificationReadAt = 'readAt';
  static const String actionUrl = 'actionUrl';
  static const String priority = 'priority';

  // Settings fields
  static const String theme = 'theme';
  static const String language = 'language';
  static const String timezone = 'timezone';
  static const String notifications = 'notifications';
  static const String privacy = 'privacy';
  static const String security = 'security';
  static const String accessibility = 'accessibility';
}

// Firestore indexes and queries
class FirestoreIndexes {
  // User indexes
  static const String usersByEmail = 'users_by_email';
  static const String usersByPhone = 'users_by_phone';
  static const String usersByCreatedAt = 'users_by_created_at';
  static const String usersByLastSeen = 'users_by_last_seen';

  // Post indexes
  static const String postsByUserId = 'posts_by_user_id';
  static const String postsByCreatedAt = 'posts_by_created_at';
  static const String postsByCategory = 'posts_by_category';
  static const String postsByTags = 'posts_by_tags';
  static const String postsByLocation = 'posts_by_location';

  // Comment indexes
  static const String commentsByPostId = 'comments_by_post_id';
  static const String commentsByUserId = 'comments_by_user_id';
  static const String commentsByParentId = 'comments_by_parent_id';

  // Message indexes
  static const String messagesByChatId = 'messages_by_chat_id';
  static const String messagesBySenderId = 'messages_by_sender_id';
  static const String messagesByReceiverId = 'messages_by_receiver_id';

  // Notification indexes
  static const String notificationsByUserId = 'notifications_by_user_id';
  static const String notificationsByType = 'notifications_by_type';
  static const String notificationsByCreatedAt = 'notifications_by_created_at';
}

// Firestore security rules constants
class FirestoreSecurity {
  // User permissions
  static const String userCanReadOwnData =
      'request.auth != null && request.auth.uid == resource.data.userId';
  static const String userCanWriteOwnData =
      'request.auth != null && request.auth.uid == resource.data.userId';
  static const String userCanDeleteOwnData =
      'request.auth != null && request.auth.uid == resource.data.userId';

  // Post permissions
  static const String userCanReadPublicPosts = 'resource.data.isPublic == true';
  static const String userCanReadOwnPosts =
      'request.auth != null && request.auth.uid == resource.data.userId';
  static const String userCanWriteOwnPosts =
      'request.auth != null && request.auth.uid == resource.data.userId';

  // Comment permissions
  static const String userCanReadComments = 'request.auth != null';
  static const String userCanWriteOwnComments =
      'request.auth != null && request.auth.uid == resource.data.userId';

  // Message permissions
  static const String userCanReadOwnMessages =
      'request.auth != null && (request.auth.uid == resource.data.senderId || request.auth.uid == resource.data.receiverId)';
  static const String userCanWriteOwnMessages =
      'request.auth != null && request.auth.uid == resource.data.senderId';
}

// Firestore batch operations
class FirestoreBatch {
  static const int maxBatchSize = 500;
  static const int maxWriteOperations = 500;
  static const int maxDeleteOperations = 500;
  static const int maxUpdateOperations = 500;
}

// Firestore query limits
class FirestoreLimits {
  static const int maxQueryResults = 1000;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int maxArrayElements = 10000;
  static const int maxDocumentSize = 1048576; // 1MB
  static const int maxFieldValueSize = 1048576; // 1MB
}
