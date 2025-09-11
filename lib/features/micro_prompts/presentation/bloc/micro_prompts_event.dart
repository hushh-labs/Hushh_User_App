part of 'micro_prompts_bloc.dart';

abstract class MicroPromptsEvent extends Equatable {
  const MicroPromptsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNextQuestion extends MicroPromptsEvent {
  final String userId;

  const LoadNextQuestion(this.userId);

  @override
  List<Object> get props => [userId];
}

class SubmitResponse extends MicroPromptsEvent {
  final String userId;
  final String questionId;
  final String responseText;

  const SubmitResponse({
    required this.userId,
    required this.questionId,
    required this.responseText,
  });

  @override
  List<Object> get props => [userId, questionId, responseText];
}

class SkipQuestion extends MicroPromptsEvent {
  final String userId;
  final String questionId;

  const SkipQuestion({required this.userId, required this.questionId});

  @override
  List<Object> get props => [userId, questionId];
}

class AskLater extends MicroPromptsEvent {
  final String userId;
  final String questionId;

  const AskLater({required this.userId, required this.questionId});

  @override
  List<Object> get props => [userId, questionId];
}

class CheckCanShowPrompt extends MicroPromptsEvent {
  final String userId;

  const CheckCanShowPrompt(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateSensitiveFlow extends MicroPromptsEvent {
  final String userId;
  final bool isInSensitiveFlow;
  final SensitiveFlowType? flowType;

  const UpdateSensitiveFlow({
    required this.userId,
    required this.isInSensitiveFlow,
    this.flowType,
  });

  @override
  List<Object?> get props => [userId, isInSensitiveFlow, flowType];
}

class UpdateCurrentScreen extends MicroPromptsEvent {
  final String userId;
  final String? screenName;

  const UpdateCurrentScreen({required this.userId, this.screenName});

  @override
  List<Object?> get props => [userId, screenName];
}

class LoadUserProfile extends MicroPromptsEvent {
  final String userId;

  const LoadUserProfile(this.userId);

  @override
  List<Object> get props => [userId];
}

class InitializeUserSchedule extends MicroPromptsEvent {
  final String userId;

  const InitializeUserSchedule(this.userId);

  @override
  List<Object> get props => [userId];
}
