import '../entities/micro_prompt_question.dart';
import '../entities/micro_prompt_response.dart';
import '../entities/micro_prompt_schedule.dart';
import '../entities/user_app_state.dart';

abstract class MicroPromptsRepository {
  // Questions
  Future<List<MicroPromptQuestion>> getAllQuestions();
  Future<MicroPromptQuestion?> getQuestionById(String questionId);
  Future<List<MicroPromptQuestion>> getQuestionsByCategory(String category);

  // User Responses
  Future<void> saveUserResponse(MicroPromptResponse response);
  Future<List<MicroPromptResponse>> getUserResponses(String userId);
  Future<List<MicroPromptResponse>> getUserResponsesByCategory(
    String userId,
    String category,
  );
  Future<MicroPromptResponse?> getUserResponseForQuestion(
    String userId,
    String questionId,
  );

  // Schedule Management
  Future<MicroPromptSchedule?> getUserSchedule(String userId);
  Future<void> saveUserSchedule(MicroPromptSchedule schedule);
  Future<void> updateUserSchedule(MicroPromptSchedule schedule);
  Future<void> updateLastPromptShown(String userId, DateTime timestamp);
  Future<void> updateNextPromptScheduled(String userId, DateTime timestamp);

  // App State Management
  Future<UserAppState?> getUserAppState(String userId);
  Future<void> saveUserAppState(UserAppState appState);
  Future<void> updateUserAppState(UserAppState appState);
  Future<void> updateSensitiveFlowState(
    String userId,
    bool isInSensitiveFlow,
    SensitiveFlowType? flowType,
  );
  Future<void> updateCurrentScreen(String userId, String? screenName);
  Future<void> updateLastActivity(String userId, DateTime timestamp);

  // Smart Query Methods
  Future<MicroPromptQuestion?> getNextAvailableQuestion(String userId);
  Future<bool> canShowPromptNow(String userId);
  Future<Map<String, dynamic>> getUserProfileInsights(String userId);
  Future<List<MicroPromptQuestion>> getUnansweredQuestions(String userId);
  Future<List<MicroPromptQuestion>> getSkippedQuestions(String userId);
  Future<int> getUserCompletionPercentage(String userId);
}
