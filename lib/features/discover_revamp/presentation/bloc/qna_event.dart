part of 'qna_bloc.dart';

abstract class QnAEvent extends Equatable {
  const QnAEvent();

  @override
  List<Object?> get props => [];
}

class StartQnASessionEvent extends QnAEvent {
  final String agentId;
  final String agentName;

  const StartQnASessionEvent({required this.agentId, required this.agentName});

  @override
  List<Object?> get props => [agentId, agentName];
}

class SubmitAnswerEvent extends QnAEvent {
  final String questionId;
  final String? selectedOption;
  final String? textAnswer;

  const SubmitAnswerEvent({
    required this.questionId,
    this.selectedOption,
    this.textAnswer,
  });

  @override
  List<Object?> get props => [questionId, selectedOption, textAnswer];
}

class CompleteQnASessionEvent extends QnAEvent {
  const CompleteQnASessionEvent();
}

class ResetQnAEvent extends QnAEvent {
  const ResetQnAEvent();
}
