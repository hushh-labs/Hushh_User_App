import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/micro_prompt_question.dart';
import '../../domain/entities/micro_prompt_response.dart';
import '../../domain/entities/micro_prompt_schedule.dart';
import '../../domain/entities/user_app_state.dart';
import '../../domain/repositories/micro_prompts_repository.dart';

part 'micro_prompts_event.dart';
part 'micro_prompts_state.dart';

class MicroPromptsBloc extends Bloc<MicroPromptsEvent, MicroPromptsState> {
  final MicroPromptsRepository _repository;
  final Uuid _uuid = const Uuid();

  MicroPromptsBloc(this._repository) : super(MicroPromptsInitial()) {
    on<LoadNextQuestion>(_onLoadNextQuestion);
    on<SubmitResponse>(_onSubmitResponse);
    on<SkipQuestion>(_onSkipQuestion);
    on<AskLater>(_onAskLater);
    on<CheckCanShowPrompt>(_onCheckCanShowPrompt);
    on<UpdateSensitiveFlow>(_onUpdateSensitiveFlow);
    on<UpdateCurrentScreen>(_onUpdateCurrentScreen);
    on<LoadUserProfile>(_onLoadUserProfile);
    on<InitializeUserSchedule>(_onInitializeUserSchedule);
  }

  Future<void> _onLoadNextQuestion(
    LoadNextQuestion event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      emit(MicroPromptsLoading());

      final canShow = await _repository.canShowPromptNow(event.userId);
      if (!canShow) {
        emit(
          const MicroPromptsNoPromptAvailable(
            'Cannot show prompt at this time',
          ),
        );
        return;
      }

      final question = await _repository.getNextAvailableQuestion(event.userId);
      if (question != null) {
        emit(MicroPromptsQuestionLoaded(question, event.userId));

        // Update last prompt shown timestamp
        await _repository.updateLastPromptShown(event.userId, DateTime.now());
      } else {
        emit(const MicroPromptsNoPromptAvailable('No questions available'));
      }
    } catch (e) {
      emit(MicroPromptsError('Failed to load question: $e'));
    }
  }

  Future<void> _onSubmitResponse(
    SubmitResponse event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      emit(MicroPromptsLoading());

      final response = MicroPromptResponse(
        id: _uuid.v4(),
        userId: event.userId,
        questionId: event.questionId,
        responseText: event.responseText,
        responseType: MicroPromptResponseType.answered,
        askedAt: DateTime.now(),
        respondedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _repository.saveUserResponse(response);
      emit(const MicroPromptsResponseSubmitted('Response saved successfully'));
    } catch (e) {
      emit(MicroPromptsError('Failed to save response: $e'));
    }
  }

  Future<void> _onSkipQuestion(
    SkipQuestion event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      emit(MicroPromptsLoading());

      final response = MicroPromptResponse(
        id: _uuid.v4(),
        userId: event.userId,
        questionId: event.questionId,
        responseText: null,
        responseType: MicroPromptResponseType.skipped,
        askedAt: DateTime.now(),
        respondedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _repository.saveUserResponse(response);
      emit(const MicroPromptsResponseSubmitted('Question skipped'));
    } catch (e) {
      emit(MicroPromptsError('Failed to skip question: $e'));
    }
  }

  Future<void> _onAskLater(
    AskLater event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      emit(MicroPromptsLoading());

      final response = MicroPromptResponse(
        id: _uuid.v4(),
        userId: event.userId,
        questionId: event.questionId,
        responseText: null,
        responseType: MicroPromptResponseType.askLater,
        askedAt: DateTime.now(),
        respondedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _repository.saveUserResponse(response);

      // Schedule next prompt for later (e.g., in 2 hours)
      final nextPromptTime = DateTime.now().add(const Duration(hours: 2));
      await _repository.updateNextPromptScheduled(event.userId, nextPromptTime);

      emit(const MicroPromptsResponseSubmitted('Will ask later'));
    } catch (e) {
      emit(MicroPromptsError('Failed to schedule for later: $e'));
    }
  }

  Future<void> _onCheckCanShowPrompt(
    CheckCanShowPrompt event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      final canShow = await _repository.canShowPromptNow(event.userId);
      emit(MicroPromptsCanShowResult(canShow));
    } catch (e) {
      emit(MicroPromptsError('Failed to check prompt availability: $e'));
    }
  }

  Future<void> _onUpdateSensitiveFlow(
    UpdateSensitiveFlow event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      await _repository.updateSensitiveFlowState(
        event.userId,
        event.isInSensitiveFlow,
        event.flowType,
      );
    } catch (e) {
      // Silent fail for app state updates
    }
  }

  Future<void> _onUpdateCurrentScreen(
    UpdateCurrentScreen event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      await _repository.updateCurrentScreen(event.userId, event.screenName);
      await _repository.updateLastActivity(event.userId, DateTime.now());
    } catch (e) {
      // Silent fail for app state updates
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      emit(MicroPromptsLoading());

      final insights = await _repository.getUserProfileInsights(event.userId);
      final completionPercentage = await _repository
          .getUserCompletionPercentage(event.userId);

      emit(MicroPromptsProfileLoaded(insights, completionPercentage));
    } catch (e) {
      emit(MicroPromptsError('Failed to load profile: $e'));
    }
  }

  Future<void> _onInitializeUserSchedule(
    InitializeUserSchedule event,
    Emitter<MicroPromptsState> emit,
  ) async {
    try {
      final existingSchedule = await _repository.getUserSchedule(event.userId);

      if (existingSchedule == null) {
        // Create default schedule
        final defaultSchedule = MicroPromptSchedule(
          id: _uuid.v4(),
          userId: event.userId,
          lastPromptShownAt: null,
          nextPromptScheduledAt: DateTime.now().add(const Duration(minutes: 2)),
          quietHoursStart: '23:00:00',
          quietHoursEnd: '07:00:00',
          timezone: 'UTC',
          isPromptsEnabled: true,
          promptFrequencyMinutes: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repository.saveUserSchedule(defaultSchedule);
      }

      // Initialize app state if it doesn't exist
      final existingAppState = await _repository.getUserAppState(event.userId);

      if (existingAppState == null) {
        final defaultAppState = UserAppState(
          id: _uuid.v4(),
          userId: event.userId,
          currentScreen: null,
          isInSensitiveFlow: false,
          sensitiveFlowType: null,
          lastActivityAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repository.saveUserAppState(defaultAppState);
      }
    } catch (e) {
      // Silent fail for initialization
    }
  }
}
