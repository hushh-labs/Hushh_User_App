import 'package:equatable/equatable.dart';

class Answer extends Equatable {
  final String questionId;
  final String? selectedOption; // For multiple choice
  final String? textAnswer; // For text input
  final DateTime answeredAt;

  const Answer({
    required this.questionId,
    this.selectedOption,
    this.textAnswer,
    required this.answeredAt,
  });

  @override
  List<Object?> get props => [
    questionId,
    selectedOption,
    textAnswer,
    answeredAt,
  ];
}
