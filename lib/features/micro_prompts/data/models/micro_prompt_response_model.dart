import '../../domain/entities/micro_prompt_response.dart';

class MicroPromptResponseModel extends MicroPromptResponse {
  const MicroPromptResponseModel({
    required super.id,
    required super.userId,
    required super.questionId,
    super.responseText,
    required super.responseType,
    required super.askedAt,
    required super.respondedAt,
    required super.createdAt,
  });

  factory MicroPromptResponseModel.fromJson(Map<String, dynamic> json) {
    return MicroPromptResponseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questionId: json['question_id'] as String,
      responseText: json['response_text'] as String?,
      responseType: MicroPromptResponseType.fromString(
        json['response_type'] as String,
      ),
      askedAt: DateTime.parse(json['asked_at'] as String),
      respondedAt: DateTime.parse(json['responded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'question_id': questionId,
      'response_text': responseText,
      'response_type': responseType.value,
      'asked_at': askedAt.toIso8601String(),
      'responded_at': respondedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MicroPromptResponseModel.fromEntity(MicroPromptResponse entity) {
    return MicroPromptResponseModel(
      id: entity.id,
      userId: entity.userId,
      questionId: entity.questionId,
      responseText: entity.responseText,
      responseType: entity.responseType,
      askedAt: entity.askedAt,
      respondedAt: entity.respondedAt,
      createdAt: entity.createdAt,
    );
  }

  MicroPromptResponse toEntity() {
    return MicroPromptResponse(
      id: id,
      userId: userId,
      questionId: questionId,
      responseText: responseText,
      responseType: responseType,
      askedAt: askedAt,
      respondedAt: respondedAt,
      createdAt: createdAt,
    );
  }
}
