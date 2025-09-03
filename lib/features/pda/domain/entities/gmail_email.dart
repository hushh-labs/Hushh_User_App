import 'package:equatable/equatable.dart';

class GmailEmail extends Equatable {
  final int? id;
  final String userId;
  final String messageId;
  final String threadId;
  final String? historyId;
  final String? subject;
  final String? fromEmail;
  final String? fromName;
  final List<String>? toEmails;
  final List<String>? ccEmails;
  final List<String>? bccEmails;
  final String? bodyText;
  final String? bodyHtml;
  final String? snippet;
  final bool isRead;
  final bool isImportant;
  final bool isStarred;
  final List<String>? labels;
  final List<dynamic>? attachments;
  final DateTime receivedAt;
  final DateTime? sentAt;
  final DateTime? syncedAt;

  const GmailEmail({
    this.id,
    required this.userId,
    required this.messageId,
    required this.threadId,
    this.historyId,
    this.subject,
    this.fromEmail,
    this.fromName,
    this.toEmails,
    this.ccEmails,
    this.bccEmails,
    this.bodyText,
    this.bodyHtml,
    this.snippet,
    this.isRead = false,
    this.isImportant = false,
    this.isStarred = false,
    this.labels,
    this.attachments,
    required this.receivedAt,
    this.sentAt,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    messageId,
    threadId,
    historyId,
    subject,
    fromEmail,
    fromName,
    toEmails,
    ccEmails,
    bccEmails,
    bodyText,
    bodyHtml,
    snippet,
    isRead,
    isImportant,
    isStarred,
    labels,
    attachments,
    receivedAt,
    sentAt,
    syncedAt,
  ];

  GmailEmail copyWith({
    int? id,
    String? userId,
    String? messageId,
    String? threadId,
    String? historyId,
    String? subject,
    String? fromEmail,
    String? fromName,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? bodyText,
    String? bodyHtml,
    String? snippet,
    bool? isRead,
    bool? isImportant,
    bool? isStarred,
    List<String>? labels,
    List<dynamic>? attachments,
    DateTime? receivedAt,
    DateTime? sentAt,
    DateTime? syncedAt,
  }) {
    return GmailEmail(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      threadId: threadId ?? this.threadId,
      historyId: historyId ?? this.historyId,
      subject: subject ?? this.subject,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      toEmails: toEmails ?? this.toEmails,
      ccEmails: ccEmails ?? this.ccEmails,
      bccEmails: bccEmails ?? this.bccEmails,
      bodyText: bodyText ?? this.bodyText,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      snippet: snippet ?? this.snippet,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      isStarred: isStarred ?? this.isStarred,
      labels: labels ?? this.labels,
      attachments: attachments ?? this.attachments,
      receivedAt: receivedAt ?? this.receivedAt,
      sentAt: sentAt ?? this.sentAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get display name for the sender
  String get displaySender {
    if (fromName != null && fromName!.isNotEmpty) {
      return fromName!;
    }
    return fromEmail ?? 'Unknown Sender';
  }

  /// Get a preview of the email content
  String get preview {
    if (snippet != null && snippet!.isNotEmpty) {
      return snippet!;
    }
    if (bodyText != null && bodyText!.isNotEmpty) {
      // Return first 150 characters of body text
      final text = bodyText!.replaceAll(RegExp(r'\s+'), ' ').trim();
      return text.length > 150 ? '${text.substring(0, 150)}...' : text;
    }
    return 'No preview available';
  }

  /// Check if email has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  /// Check if email is from today
  bool get isFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(
      receivedAt.year,
      receivedAt.month,
      receivedAt.day,
    );
    return emailDate.isAtSameMomentAs(today);
  }

  /// Check if email is from this week
  bool get isFromThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return receivedAt.isAfter(weekStart);
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(receivedAt);

    if (difference.inDays == 0) {
      // Today - show time
      return '${receivedAt.hour.toString().padLeft(2, '0')}:${receivedAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[receivedAt.weekday - 1];
    } else {
      // Older - show date
      return '${receivedAt.day}/${receivedAt.month}/${receivedAt.year}';
    }
  }
}
