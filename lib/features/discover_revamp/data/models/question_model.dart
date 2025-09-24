import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.text,
    required super.type,
    super.options,
    super.placeholder,
    required super.order,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
      ),
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      placeholder: json['placeholder'] as String?,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toString().split('.').last,
      'options': options,
      'placeholder': placeholder,
      'order': order,
    };
  }

  factory QuestionModel.fromEntity(Question question) {
    return QuestionModel(
      id: question.id,
      text: question.text,
      type: question.type,
      options: question.options,
      placeholder: question.placeholder,
      order: question.order,
    );
  }
}
