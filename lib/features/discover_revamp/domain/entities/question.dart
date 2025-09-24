import 'package:equatable/equatable.dart';

enum QuestionType { multipleChoice, textInput }

class Question extends Equatable {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options; // For multiple choice questions
  final String? placeholder; // For text input questions
  final int order;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.placeholder,
    required this.order,
  });

  @override
  List<Object?> get props => [id, text, type, options, placeholder, order];
}
