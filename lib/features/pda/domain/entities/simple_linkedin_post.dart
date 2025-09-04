class LinkedInPost {
  final String id;
  final String userId;
  final String linkedinAccountId;
  final String postId;
  final String? content;
  final String? postType;
  final String? visibility;
  final List<String> mediaUrls;
  final String? articleUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime? postedAt;
  final DateTime fetchedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LinkedInPost({
    required this.id,
    required this.userId,
    required this.linkedinAccountId,
    required this.postId,
    this.content,
    this.postType,
    this.visibility,
    this.mediaUrls = const [],
    this.articleUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.postedAt,
    required this.fetchedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get isArticle => articleUrl != null;
  bool get hasEngagement => likeCount > 0 || commentCount > 0 || shareCount > 0;

  int get totalEngagement => likeCount + commentCount + shareCount;

  String get shortContent {
    if (content == null) return '';
    if (content!.length <= 100) return content!;
    return '${content!.substring(0, 100)}...';
  }

  String get postTypeDisplay {
    switch (postType?.toLowerCase()) {
      case 'article':
        return 'Article';
      case 'image':
        return 'Image Post';
      case 'video':
        return 'Video Post';
      case 'document':
        return 'Document';
      default:
        return 'Post';
    }
  }

  // Factory constructors
  factory LinkedInPost.fromJson(Map<String, dynamic> json) {
    return LinkedInPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      linkedinAccountId: json['linkedin_account_id'] as String,
      postId: json['post_id'] as String,
      content: json['content'] as String?,
      postType: json['post_type'] as String?,
      visibility: json['visibility'] as String?,
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'] as List)
          : [],
      articleUrl: json['article_url'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      postedAt: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'] as String)
          : null,
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'linkedin_account_id': linkedinAccountId,
      'post_id': postId,
      'content': content,
      'post_type': postType,
      'visibility': visibility,
      'media_urls': mediaUrls,
      'article_url': articleUrl,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'posted_at': postedAt?.toIso8601String(),
      'fetched_at': fetchedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LinkedInPost copyWith({
    String? id,
    String? userId,
    String? linkedinAccountId,
    String? postId,
    String? content,
    String? postType,
    String? visibility,
    List<String>? mediaUrls,
    String? articleUrl,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? postedAt,
    DateTime? fetchedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkedInPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      linkedinAccountId: linkedinAccountId ?? this.linkedinAccountId,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      visibility: visibility ?? this.visibility,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      articleUrl: articleUrl ?? this.articleUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      postedAt: postedAt ?? this.postedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LinkedInPost{id: $id, postType: $postType, content: ${shortContent}, engagement: $totalEngagement}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkedInPost && other.id == id && other.postId == postId;
  }

  @override
  int get hashCode => id.hashCode ^ postId.hashCode;
}
