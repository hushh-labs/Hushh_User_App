part of 'micro_prompts_bloc.dart';

abstract class MicroPromptsState extends Equatable {
  const MicroPromptsState();

  @override
  List<Object?> get props => [];
}

class MicroPromptsInitial extends MicroPromptsState {}

class MicroPromptsLoading extends MicroPromptsState {}

class MicroPromptsQuestionLoaded extends MicroPromptsState {
  final MicroPromptQuestion question;
  final String userId;

  const MicroPromptsQuestionLoaded(this.question, this.userId);

  @override
  List<Object> get props => [question, userId];
}

class MicroPromptsResponseSubmitted extends MicroPromptsState {
  final String message;

  const MicroPromptsResponseSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

class MicroPromptsNoPromptAvailable extends MicroPromptsState {
  final String reason;

  const MicroPromptsNoPromptAvailable(this.reason);

  @override
  List<Object> get props => [reason];
}

class MicroPromptsCanShowResult extends MicroPromptsState {
  final bool canShow;

  const MicroPromptsCanShowResult(this.canShow);

  @override
  List<Object> get props => [canShow];
}

class MicroPromptsProfileLoaded extends MicroPromptsState {
  final Map<String, dynamic> insights;
  final int completionPercentage;

  const MicroPromptsProfileLoaded(this.insights, this.completionPercentage);

  @override
  List<Object> get props => [insights, completionPercentage];
}

class MicroPromptsError extends MicroPromptsState {
  final String message;

  const MicroPromptsError(this.message);

  @override
  List<Object> get props => [message];
}
