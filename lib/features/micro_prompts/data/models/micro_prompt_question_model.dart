import '../../domain/entities/micro_prompt_question.dart';

class MicroPromptQuestionModel extends MicroPromptQuestion {
  const MicroPromptQuestionModel({
    required super.id,
    required super.questionText,
    required super.category,
    required super.questionOrder,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MicroPromptQuestionModel.fromJson(Map<String, dynamic> json) {
    return MicroPromptQuestionModel(
      id: json['id'] as String,
      questionText: json['question_text'] as String,
      category: json['category'] as String,
      questionOrder: json['question_order'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
      'question_order': questionOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MicroPromptQuestionModel.fromEntity(MicroPromptQuestion entity) {
    return MicroPromptQuestionModel(
      id: entity.id,
      questionText: entity.questionText,
      category: entity.category,
      questionOrder: entity.questionOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MicroPromptQuestion toEntity() {
    return MicroPromptQuestion(
      id: id,
      questionText: questionText,
      category: category,
      questionOrder: questionOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
