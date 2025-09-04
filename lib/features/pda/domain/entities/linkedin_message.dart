import 'package:equatable/equatable.dart';

class LinkedInMessage extends Equatable {
  final int? id;
  final String userId;
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final List<String>? recipientIds;
  final List<String>? participantIds;
  final String? subject;
  final String? body;
  final String? messageType;
  final bool isRead;
  final bool isStarred;
  final String? priority;
  final List<dynamic>? attachments;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? syncedAt;

  const LinkedInMessage({
    this.id,
    required this.userId,
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.recipientIds,
    this.participantIds,
    this.subject,
    this.body,
    this.messageType,
    this.isRead = false,
    this.isStarred = false,
    this.priority,
    this.attachments,
    required this.sentAt,
    this.readAt,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    messageId,
    conversationId,
    senderId,
    senderName,
    recipientIds,
    participantIds,
    subject,
    body,
    messageType,
    isRead,
    isStarred,
    priority,
    attachments,
    sentAt,
    readAt,
    syncedAt,
  ];

  LinkedInMessage copyWith({
    int? id,
    String? userId,
    String? messageId,
    String? conversationId,
    String? senderId,
    String? senderName,
    List<String>? recipientIds,
    List<String>? participantIds,
    String? subject,
    String? body,
    String? messageType,
    bool? isRead,
    bool? isStarred,
    String? priority,
    List<dynamic>? attachments,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? syncedAt,
  }) {
    return LinkedInMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientIds: recipientIds ?? this.recipientIds,
      participantIds: participantIds ?? this.participantIds,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get display sender name
  String get displaySender {
    return senderName ?? 'LinkedIn User';
  }

  /// Get message preview (first 100 characters)
  String get preview {
    if (body != null && body!.isNotEmpty) {
      final cleanBody = body!.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanBody.length <= 100) return cleanBody;
      return '${cleanBody.substring(0, 100)}...';
    }
    return '';
  }

  /// Get subject display (fallback to preview if no subject)
  String get subjectDisplay {
    if (subject != null && subject!.isNotEmpty) {
      return subject!;
    }
    final bodyPreview = preview;
    return bodyPreview.isNotEmpty ? bodyPreview : 'LinkedIn Message';
  }

  /// Check if message has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  /// Get attachment count
  int get attachmentCount => attachments?.length ?? 0;

  /// Get formatted sent time
  String get formattedSentTime {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inDays > 365) {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    } else if (difference.inDays > 7) {
      return '${sentAt.day}/${sentAt.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if message is unread
  bool get isUnread => !isRead;

  /// Get message type display
  String get messageTypeDisplay {
    switch (messageType?.toUpperCase()) {
      case 'INMAIL':
        return 'InMail';
      case 'MESSAGE':
        return 'Message';
      case 'SPONSORED_INMAIL':
        return 'Sponsored InMail';
      default:
        return messageType ?? 'Message';
    }
  }

  /// Get priority display
  String get priorityDisplay {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return 'High Priority';
      case 'MEDIUM':
        return 'Medium Priority';
      case 'LOW':
        return 'Low Priority';
      default:
        return '';
    }
  }

  /// Check if message is high priority
  bool get isHighPriority => priority?.toUpperCase() == 'HIGH';

  /// Get participant count
  int get participantCount => participantIds?.length ?? 0;

  /// Check if this is a group conversation
  bool get isGroupConversation => participantCount > 2;

  /// Get recipient count
  int get recipientCount => recipientIds?.length ?? 0;
}

