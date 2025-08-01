import 'package:equatable/equatable.dart';

enum MessageType { text, image, file }

class PdaMessage extends Equatable {
  final String id;
  final String hushhId;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? metadata;

  const PdaMessage({
    required this.id,
    required this.hushhId,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.metadata,
  });

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
