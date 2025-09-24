part of 'qna_bloc.dart';

abstract class QnAState extends Equatable {
  const QnAState();

  @override
  List<Object?> get props => [];
}

class QnAInitial extends QnAState {}

class QnALoading extends QnAState {}

class QnASessionActive extends QnAState {
  final QnASession session;
  final int currentQuestionIndex;
  final bool canProceed;
  final bool isSubmitting;

  const QnASessionActive({
    required this.session,
    required this.currentQuestionIndex,
    required this.canProceed,
    this.isSubmitting = false,
  });

  QnASessionActive copyWith({
    QnASession? session,
    int? currentQuestionIndex,
    bool? canProceed,
    bool? isSubmitting,
  }) {
    return QnASessionActive(
      session: session ?? this.session,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      canProceed: canProceed ?? this.canProceed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    session,
    currentQuestionIndex,
    canProceed,
    isSubmitting,
  ];
}

class QnASessionCompleted extends QnAState {
  final QnASession session;

  const QnASessionCompleted({required this.session});

  @override
  List<Object?> get props => [session];
}

class QnAError extends QnAState {
  final String message;

  const QnAError({required this.message});

  @override
  List<Object?> get props => [message];
}
