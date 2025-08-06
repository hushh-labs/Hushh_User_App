class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastText;
  final DateTime? lastTextTime;
  final String? lastTextBy;
  final bool? isLastTextSeen;
  final DateTime createdAt;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastText,
    this.lastTextTime,
    this.lastTextBy,
    this.isLastTextSeen,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'lastText': lastText,
      'lastTextTime': lastTextTime?.millisecondsSinceEpoch,
      'lastTextBy': lastTextBy,
      'isLastTextSeen': isLastTextSeen,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ChatModel.fromJson(String id, Map<String, dynamic> json) {
    return ChatModel(
      id: id,
      participants: List<String>.from(json['participants'] ?? []),
      lastText: json['lastText'],
      lastTextTime: json['lastTextTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastTextTime'])
          : null,
      lastTextBy: json['lastTextBy'],
      isLastTextSeen: json['isLastTextSeen'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;
  final bool isSeen;
  final String? mediaUrl;
  final String? mediaType;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.type,
    this.isSeen = false,
    this.mediaUrl,
    this.mediaType,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'isSeen': isSeen,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }

  factory MessageModel.fromJson(String id, Map<String, dynamic> json) {
    return MessageModel(
      id: id,
      text: json['text'] ?? '',
      senderId: json['senderId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      isSeen: json['isSeen'] ?? false,
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
    );
  }
}

enum MessageType { text, image, video, audio, file }
