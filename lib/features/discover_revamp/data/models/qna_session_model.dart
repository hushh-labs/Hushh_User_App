import '../../domain/entities/qna_session.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import 'question_model.dart';
import 'answer_model.dart';

class QnASessionModel extends QnASession {
  const QnASessionModel({
    required super.id,
    required super.agentId,
    required super.agentName,
    required super.questions,
    required super.answers,
    required super.createdAt,
    super.completedAt,
    required super.isCompleted,
  });

  factory QnASessionModel.fromJson(Map<String, dynamic> json) {
    return QnASessionModel(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      answers: (json['answers'] as List)
          .map((a) => AnswerModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'agentName': agentName,
      'questions': questions.map((q) => (q as QuestionModel).toJson()).toList(),
      'answers': answers.map((a) => (a as AnswerModel).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory QnASessionModel.fromEntity(QnASession session) {
    return QnASessionModel(
      id: session.id,
      agentId: session.agentId,
      agentName: session.agentName,
      questions: session.questions,
      answers: session.answers,
      createdAt: session.createdAt,
      completedAt: session.completedAt,
      isCompleted: session.isCompleted,
    );
  }
}
