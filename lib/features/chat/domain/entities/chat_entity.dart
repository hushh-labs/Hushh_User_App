import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participants;
  final String? lastText;
  final DateTime? lastTextTime;
  final String? lastTextBy;
  final bool? isLastTextSeen;
  final DateTime createdAt;
  final bool isUnread;

  const ChatEntity({
    required this.id,
    required this.participants,
    this.lastText,
    this.lastTextTime,
    this.lastTextBy,
    this.isLastTextSeen,
    required this.createdAt,
    this.isUnread = false,
  });

  @override
  List<Object?> get props => [
    id,
    participants,
    lastText,
    lastTextTime,
    lastTextBy,
    isLastTextSeen,
    createdAt,
    isUnread,
  ];
}

class MessageEntity extends Equatable {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;
  final bool isSeen;
  final String? mediaUrl;
  final String? mediaType;

  const MessageEntity({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.type,
    this.isSeen = false,
    this.mediaUrl,
    this.mediaType,
  });

  @override
  List<Object?> get props => [
    id,
    text,
    senderId,
    timestamp,
    type,
    isSeen,
    mediaUrl,
    mediaType,
  ];
}

enum MessageType { text, image, video, audio, file }

class TypingStatusEntity extends Equatable {
  final String chatId;
  final String userId;
  final bool isTyping;

  const TypingStatusEntity({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatId, userId, isTyping];
}
