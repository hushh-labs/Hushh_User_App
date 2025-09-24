import 'package:equatable/equatable.dart';
import 'question.dart';
import 'answer.dart';

class QnASession extends Equatable {
  final String id;
  final String agentId;
  final String agentName;
  final List<Question> questions;
  final List<Answer> answers;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;

  const QnASession({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.questions,
    required this.answers,
    required this.createdAt,
    this.completedAt,
    required this.isCompleted,
  });

  QnASession copyWith({
    String? id,
    String? agentId,
    String? agentName,
    List<Question>? questions,
    List<Answer>? answers,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return QnASession(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    agentId,
    agentName,
    questions,
    answers,
    createdAt,
    completedAt,
    isCompleted,
  ];
}
