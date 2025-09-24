import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/qna_session.dart';
import '../../domain/entities/answer.dart';
import '../../domain/usecases/start_qna_session.dart';
import '../../domain/usecases/submit_answer.dart';
import '../../domain/usecases/complete_qna_session.dart';

part 'qna_event.dart';
part 'qna_state.dart';

class QnABloc extends Bloc<QnAEvent, QnAState> {
  final StartQnASession startQnASession;
  final SubmitAnswer submitAnswer;
  final CompleteQnASession completeQnASession;

  QnABloc({
    required this.startQnASession,
    required this.submitAnswer,
    required this.completeQnASession,
  }) : super(QnAInitial()) {
    on<StartQnASessionEvent>(_onStartQnASession);
    on<SubmitAnswerEvent>(_onSubmitAnswer);
    on<CompleteQnASessionEvent>(_onCompleteQnASession);
    on<ResetQnAEvent>(_onResetQnA);
  }

  Future<void> _onStartQnASession(
    StartQnASessionEvent event,
    Emitter<QnAState> emit,
  ) async {
    emit(QnALoading());

    final result = await startQnASession(
      StartQnASessionParams(agentId: event.agentId, agentName: event.agentName),
    );

    result.fold(
      (failure) => emit(QnAError(message: failure.message)),
      (session) => emit(
        QnASessionActive(
          session: session,
          currentQuestionIndex: 0,
          canProceed: false,
        ),
      ),
    );
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswerEvent event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnASessionActive) return;

    final currentState = state as QnASessionActive;
    emit(currentState.copyWith(isSubmitting: true));

    final answer = Answer(
      questionId: event.questionId,
      selectedOption: event.selectedOption,
      textAnswer: event.textAnswer,
      answeredAt: DateTime.now(),
    );

    final result = await submitAnswer(
      SubmitAnswerParams(sessionId: currentState.session.id, answer: answer),
    );

    result.fold((failure) => emit(QnAError(message: failure.message)), (
      updatedSession,
    ) {
      final newAnswers = List<Answer>.from(currentState.session.answers)
        ..add(answer);

      final newSession = updatedSession.copyWith(answers: newAnswers);
      final nextQuestionIndex = currentState.currentQuestionIndex + 1;
      final isLastQuestion = nextQuestionIndex >= newSession.questions.length;

      if (isLastQuestion) {
        emit(
          QnASessionActive(
            session: newSession,
            currentQuestionIndex: nextQuestionIndex,
            canProceed: true,
            isSubmitting: false,
          ),
        );
      } else {
        emit(
          QnASessionActive(
            session: newSession,
            currentQuestionIndex: nextQuestionIndex,
            canProceed: false,
            isSubmitting: false,
          ),
        );
      }
    });
  }

  Future<void> _onCompleteQnASession(
    CompleteQnASessionEvent event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnASessionActive) return;

    final currentState = state as QnASessionActive;
    emit(QnALoading());

    final result = await completeQnASession(currentState.session.id);

    result.fold(
      (failure) => emit(QnAError(message: failure.message)),
      (completedSession) =>
          emit(QnASessionCompleted(session: completedSession)),
    );
  }

  void _onResetQnA(ResetQnAEvent event, Emitter<QnAState> emit) {
    emit(QnAInitial());
  }
}
