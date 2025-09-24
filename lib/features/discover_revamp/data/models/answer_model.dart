import '../../domain/entities/answer.dart';

class AnswerModel extends Answer {
  const AnswerModel({
    required super.questionId,
    super.selectedOption,
    super.textAnswer,
    required super.answeredAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['questionId'] as String,
      selectedOption: json['selectedOption'] as String?,
      textAnswer: json['textAnswer'] as String?,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
      'textAnswer': textAnswer,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory AnswerModel.fromEntity(Answer answer) {
    return AnswerModel(
      questionId: answer.questionId,
      selectedOption: answer.selectedOption,
      textAnswer: answer.textAnswer,
      answeredAt: answer.answeredAt,
    );
  }
}
