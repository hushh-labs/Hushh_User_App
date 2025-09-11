enum MicroPromptResponseType {
  answered,
  skipped,
  askLater;

  String get value {
    switch (this) {
      case MicroPromptResponseType.answered:
        return 'answered';
      case MicroPromptResponseType.skipped:
        return 'skipped';
      case MicroPromptResponseType.askLater:
        return 'ask_later';
    }
  }

  static MicroPromptResponseType fromString(String value) {
    switch (value) {
      case 'answered':
        return MicroPromptResponseType.answered;
      case 'skipped':
        return MicroPromptResponseType.skipped;
      case 'ask_later':
        return MicroPromptResponseType.askLater;
      default:
        throw ArgumentError('Invalid response type: $value');
    }
  }
}

class MicroPromptResponse {
  final String id;
  final String userId;
  final String questionId;
  final String? responseText;
  final MicroPromptResponseType responseType;
  final DateTime askedAt;
  final DateTime respondedAt;
  final DateTime createdAt;

  const MicroPromptResponse({
    required this.id,
    required this.userId,
    required this.questionId,
    this.responseText,
    required this.responseType,
    required this.askedAt,
    required this.respondedAt,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroPromptResponse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MicroPromptResponse{id: $id, userId: $userId, questionId: $questionId, responseType: $responseType}';
  }
}
