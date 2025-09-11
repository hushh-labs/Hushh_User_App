import '../models/micro_prompt_question_model.dart';
import '../models/micro_prompt_response_model.dart';
import '../models/micro_prompt_schedule_model.dart';
import '../models/user_app_state_model.dart';

abstract class MicroPromptsSupabaseDataSource {
  // Questions
  Future<List<MicroPromptQuestionModel>> getAllQuestions();
  Future<MicroPromptQuestionModel?> getQuestionById(String questionId);
  Future<List<MicroPromptQuestionModel>> getQuestionsByCategory(
    String category,
  );

  // User Responses
  Future<void> saveUserResponse(MicroPromptResponseModel response);
  Future<List<MicroPromptResponseModel>> getUserResponses(String userId);
  Future<List<MicroPromptResponseModel>> getUserResponsesByCategory(
    String userId,
    String category,
  );
  Future<MicroPromptResponseModel?> getUserResponseForQuestion(
    String userId,
    String questionId,
  );

  // Schedule Management
  Future<MicroPromptScheduleModel?> getUserSchedule(String userId);
  Future<void> saveUserSchedule(MicroPromptScheduleModel schedule);
  Future<void> updateUserSchedule(MicroPromptScheduleModel schedule);
  Future<void> updateLastPromptShown(String userId, DateTime timestamp);
  Future<void> updateNextPromptScheduled(String userId, DateTime timestamp);

  // App State Management
  Future<UserAppStateModel?> getUserAppState(String userId);
  Future<void> saveUserAppState(UserAppStateModel appState);
  Future<void> updateUserAppState(UserAppStateModel appState);
  Future<void> updateSensitiveFlowState(
    String userId,
    bool isInSensitiveFlow,
    String? flowType,
  );
  Future<void> updateCurrentScreen(String userId, String? screenName);
  Future<void> updateLastActivity(String userId, DateTime timestamp);

  // Smart Query Methods
  Future<MicroPromptQuestionModel?> getNextAvailableQuestion(String userId);
  Future<bool> canShowPromptNow(String userId);
  Future<Map<String, dynamic>> getUserProfileInsights(String userId);
  Future<List<MicroPromptQuestionModel>> getUnansweredQuestions(String userId);
  Future<List<MicroPromptQuestionModel>> getSkippedQuestions(String userId);
  Future<int> getUserCompletionPercentage(String userId);
}
