import '../../domain/entities/micro_prompt_question.dart';
import '../../domain/entities/micro_prompt_response.dart';
import '../../domain/entities/micro_prompt_schedule.dart';
import '../../domain/entities/user_app_state.dart';
import '../../domain/repositories/micro_prompts_repository.dart';
import '../data_sources/micro_prompts_supabase_data_source.dart';
import '../models/micro_prompt_question_model.dart';
import '../models/micro_prompt_response_model.dart';
import '../models/micro_prompt_schedule_model.dart';
import '../models/user_app_state_model.dart';

class MicroPromptsRepositoryImpl implements MicroPromptsRepository {
  final MicroPromptsSupabaseDataSource _dataSource;

  MicroPromptsRepositoryImpl(this._dataSource);

  @override
  Future<List<MicroPromptQuestion>> getAllQuestions() async {
    final models = await _dataSource.getAllQuestions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<MicroPromptQuestion?> getQuestionById(String questionId) async {
    final model = await _dataSource.getQuestionById(questionId);
    return model?.toEntity();
  }

  @override
  Future<List<MicroPromptQuestion>> getQuestionsByCategory(
    String category,
  ) async {
    final models = await _dataSource.getQuestionsByCategory(category);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveUserResponse(MicroPromptResponse response) async {
    final model = MicroPromptResponseModel.fromEntity(response);
    await _dataSource.saveUserResponse(model);
  }

  @override
  Future<List<MicroPromptResponse>> getUserResponses(String userId) async {
    final models = await _dataSource.getUserResponses(userId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MicroPromptResponse>> getUserResponsesByCategory(
    String userId,
    String category,
  ) async {
    final models = await _dataSource.getUserResponsesByCategory(
      userId,
      category,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<MicroPromptResponse?> getUserResponseForQuestion(
    String userId,
    String questionId,
  ) async {
    final model = await _dataSource.getUserResponseForQuestion(
      userId,
      questionId,
    );
    return model?.toEntity();
  }

  @override
  Future<MicroPromptSchedule?> getUserSchedule(String userId) async {
    final model = await _dataSource.getUserSchedule(userId);
    return model?.toEntity();
  }

  @override
  Future<void> saveUserSchedule(MicroPromptSchedule schedule) async {
    final model = MicroPromptScheduleModel.fromEntity(schedule);
    await _dataSource.saveUserSchedule(model);
  }

  @override
  Future<void> updateUserSchedule(MicroPromptSchedule schedule) async {
    final model = MicroPromptScheduleModel.fromEntity(schedule);
    await _dataSource.updateUserSchedule(model);
  }

  @override
  Future<void> updateLastPromptShown(String userId, DateTime timestamp) async {
    await _dataSource.updateLastPromptShown(userId, timestamp);
  }

  @override
  Future<void> updateNextPromptScheduled(
    String userId,
    DateTime timestamp,
  ) async {
    await _dataSource.updateNextPromptScheduled(userId, timestamp);
  }

  @override
  Future<UserAppState?> getUserAppState(String userId) async {
    final model = await _dataSource.getUserAppState(userId);
    return model?.toEntity();
  }

  @override
  Future<void> saveUserAppState(UserAppState appState) async {
    final model = UserAppStateModel.fromEntity(appState);
    await _dataSource.saveUserAppState(model);
  }

  @override
  Future<void> updateUserAppState(UserAppState appState) async {
    final model = UserAppStateModel.fromEntity(appState);
    await _dataSource.updateUserAppState(model);
  }

  @override
  Future<void> updateSensitiveFlowState(
    String userId,
    bool isInSensitiveFlow,
    SensitiveFlowType? flowType,
  ) async {
    await _dataSource.updateSensitiveFlowState(
      userId,
      isInSensitiveFlow,
      flowType?.value,
    );
  }

  @override
  Future<void> updateCurrentScreen(String userId, String? screenName) async {
    await _dataSource.updateCurrentScreen(userId, screenName);
  }

  @override
  Future<void> updateLastActivity(String userId, DateTime timestamp) async {
    await _dataSource.updateLastActivity(userId, timestamp);
  }

  @override
  Future<MicroPromptQuestion?> getNextAvailableQuestion(String userId) async {
    final model = await _dataSource.getNextAvailableQuestion(userId);
    return model?.toEntity();
  }

  @override
  Future<bool> canShowPromptNow(String userId) async {
    return await _dataSource.canShowPromptNow(userId);
  }

  @override
  Future<Map<String, dynamic>> getUserProfileInsights(String userId) async {
    return await _dataSource.getUserProfileInsights(userId);
  }

  @override
  Future<List<MicroPromptQuestion>> getUnansweredQuestions(
    String userId,
  ) async {
    final models = await _dataSource.getUnansweredQuestions(userId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MicroPromptQuestion>> getSkippedQuestions(String userId) async {
    final models = await _dataSource.getSkippedQuestions(userId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<int> getUserCompletionPercentage(String userId) async {
    return await _dataSource.getUserCompletionPercentage(userId);
  }
}
