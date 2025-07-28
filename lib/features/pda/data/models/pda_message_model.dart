import 'package:equatable/equatable.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';

class PdaMessageModel extends Equatable {
  final String id;
  final String hushhId;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? metadata;

  const PdaMessageModel({
    required this.id,
    required this.hushhId,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.metadata,
  });

  factory PdaMessageModel.fromJson(Map<String, dynamic> json) {
    return PdaMessageModel(
      id: json['id'] ?? '',
      hushhId: json['hushh_id'] ?? '',
      content: json['content'] ?? '',
      isFromUser: json['is_from_user'] ?? false,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      messageType: _parseMessageType(json['message_type']),
      metadata: json['metadata'],
    );
  }

  factory PdaMessageModel.fromDomain(PdaMessage message) {
    return PdaMessageModel(
      id: message.id,
      hushhId: message.hushhId,
      content: message.content,
      isFromUser: message.isFromUser,
      timestamp: message.timestamp,
      messageType: message.messageType,
      metadata: message.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hushh_id': hushhId,
      'content': content,
      'is_from_user': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'message_type': messageType.name,
      'metadata': metadata,
    };
  }

  PdaMessage toDomain() {
    return PdaMessage(
      id: id,
      hushhId: hushhId,
      content: content,
      isFromUser: isFromUser,
      timestamp: timestamp,
      messageType: messageType,
      metadata: metadata,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  @override
  List<Object?> get props => [
    id,
    hushhId,
    content,
    isFromUser,
    timestamp,
    messageType,
    metadata,
  ];
}
