import 'package:equatable/equatable.dart';

class LinkedInPost extends Equatable {
  final int? id;
  final String userId;
  final String postId;
  final String authorId;
  final String? authorName;
  final String? authorHeadline;
  final String? authorProfilePictureUrl;
  final String? text;
  final List<dynamic>? images;
  final List<dynamic>? videos;
  final List<dynamic>? documents;
  final String? articleUrl;
  final String? articleTitle;
  final String? articleDescription;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isSponsored;
  final String? visibility;
  final String? language;
  final DateTime publishedAt;
  final DateTime? lastUpdatedAt;
  final DateTime? syncedAt;

  const LinkedInPost({
    this.id,
    required this.userId,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.authorHeadline,
    this.authorProfilePictureUrl,
    this.text,
    this.images,
    this.videos,
    this.documents,
    this.articleUrl,
    this.articleTitle,
    this.articleDescription,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isSponsored = false,
    this.visibility,
    this.language,
    required this.publishedAt,
    this.lastUpdatedAt,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    postId,
    authorId,
    authorName,
    authorHeadline,
    authorProfilePictureUrl,
    text,
    images,
    videos,
    documents,
    articleUrl,
    articleTitle,
    articleDescription,
    likesCount,
    commentsCount,
    sharesCount,
    viewsCount,
    isSponsored,
    visibility,
    language,
    publishedAt,
    lastUpdatedAt,
    syncedAt,
  ];

  LinkedInPost copyWith({
    int? id,
    String? userId,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorHeadline,
    String? authorProfilePictureUrl,
    String? text,
    List<dynamic>? images,
    List<dynamic>? videos,
    List<dynamic>? documents,
    String? articleUrl,
    String? articleTitle,
    String? articleDescription,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isSponsored,
    String? visibility,
    String? language,
    DateTime? publishedAt,
    DateTime? lastUpdatedAt,
    DateTime? syncedAt,
  }) {
    return LinkedInPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorHeadline: authorHeadline ?? this.authorHeadline,
      authorProfilePictureUrl:
          authorProfilePictureUrl ?? this.authorProfilePictureUrl,
      text: text ?? this.text,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      documents: documents ?? this.documents,
      articleUrl: articleUrl ?? this.articleUrl,
      articleTitle: articleTitle ?? this.articleTitle,
      articleDescription: articleDescription ?? this.articleDescription,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isSponsored: isSponsored ?? this.isSponsored,
      visibility: visibility ?? this.visibility,
      language: language ?? this.language,
      publishedAt: publishedAt ?? this.publishedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get display name for the post author
  String get displayAuthor {
    if (authorName != null && authorName!.isNotEmpty) {
      return authorName!;
    }
    return 'LinkedIn User';
  }

  /// Get a preview of the post content
  String get preview {
    if (text != null && text!.isNotEmpty) {
      final cleanText = text!.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanText.length <= 150) return cleanText;
      return '${cleanText.substring(0, 150)}...';
    }

    if (articleTitle != null && articleTitle!.isNotEmpty) {
      return 'Shared article: ${articleTitle!}';
    }

    if (images != null && images!.isNotEmpty) {
      return 'Post with ${images!.length} image${images!.length > 1 ? 's' : ''}';
    }

    if (videos != null && videos!.isNotEmpty) {
      return 'Post with video content';
    }

    return 'LinkedIn post';
  }

  /// Get total engagement count
  int get totalEngagement => likesCount + commentsCount + sharesCount;

  /// Check if post has media content
  bool get hasMedia {
    return (images != null && images!.isNotEmpty) ||
        (videos != null && videos!.isNotEmpty) ||
        (documents != null && documents!.isNotEmpty);
  }

  /// Check if post is a shared article
  bool get isArticleShare => articleUrl != null && articleUrl!.isNotEmpty;

  /// Get content type description
  String get contentType {
    if (isArticleShare) return 'Article';
    if (videos != null && videos!.isNotEmpty) return 'Video';
    if (images != null && images!.isNotEmpty) return 'Image';
    if (documents != null && documents!.isNotEmpty) return 'Document';
    return 'Text';
  }

  /// Format published date for display
  String get formattedPublishedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

