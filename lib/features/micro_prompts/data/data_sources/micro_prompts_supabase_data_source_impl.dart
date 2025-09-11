import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/core/config/supabase_init.dart';

import 'micro_prompts_supabase_data_source.dart';
import '../models/micro_prompt_question_model.dart';
import '../models/micro_prompt_response_model.dart';
import '../models/micro_prompt_schedule_model.dart';
import '../models/user_app_state_model.dart';

class MicroPromptsSupabaseDataSourceImpl
    implements MicroPromptsSupabaseDataSource {
  final SupabaseClient _supabase;

  MicroPromptsSupabaseDataSourceImpl({SupabaseClient? supabase})
    : _supabase =
          supabase ?? (SupabaseInit.serviceClient ?? Supabase.instance.client);

  @override
  Future<List<MicroPromptQuestionModel>> getAllQuestions() async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting all questions');

      final response = await _supabase
          .from('micro_prompt_questions')
          .select()
          .eq('is_active', true)
          .order('question_order', ascending: true);

      final questions = response
          .map<MicroPromptQuestionModel>(
            (json) => MicroPromptQuestionModel.fromJson(json),
          )
          .toList();

      debugPrint('✅ [MICRO PROMPTS] Found ${questions.length} questions');
      return questions;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting questions: $e');
      throw Exception('Failed to get questions: $e');
    }
  }

  @override
  Future<MicroPromptQuestionModel?> getQuestionById(String questionId) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting question by ID: $questionId');

      final response = await _supabase
          .from('micro_prompt_questions')
          .select()
          .eq('id', questionId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [MICRO PROMPTS] Question found');
        return MicroPromptQuestionModel.fromJson(response);
      }

      debugPrint('ℹ️ [MICRO PROMPTS] No question found');
      return null;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting question: $e');
      throw Exception('Failed to get question: $e');
    }
  }

  @override
  Future<List<MicroPromptQuestionModel>> getQuestionsByCategory(
    String category,
  ) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting questions by category: $category');

      final response = await _supabase
          .from('micro_prompt_questions')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('question_order', ascending: true);

      final questions = response
          .map<MicroPromptQuestionModel>(
            (json) => MicroPromptQuestionModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [MICRO PROMPTS] Found ${questions.length} questions in category',
      );
      return questions;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting questions by category: $e');
      throw Exception('Failed to get questions by category: $e');
    }
  }

  @override
  Future<void> saveUserResponse(MicroPromptResponseModel response) async {
    try {
      debugPrint(
        '💾 [MICRO PROMPTS] Saving user response for user: ${response.userId}',
      );

      await _supabase
          .from('user_micro_prompt_responses')
          .upsert(response.toJson());

      debugPrint('✅ [MICRO PROMPTS] User response saved successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error saving user response: $e');
      throw Exception('Failed to save user response: $e');
    }
  }

  @override
  Future<List<MicroPromptResponseModel>> getUserResponses(String userId) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting user responses for: $userId');

      final response = await _supabase
          .from('user_micro_prompt_responses')
          .select()
          .eq('userId', userId)
          .order('responded_at', ascending: false);

      final responses = response
          .map<MicroPromptResponseModel>(
            (json) => MicroPromptResponseModel.fromJson(json),
          )
          .toList();

      debugPrint('✅ [MICRO PROMPTS] Found ${responses.length} user responses');
      return responses;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting user responses: $e');
      throw Exception('Failed to get user responses: $e');
    }
  }

  @override
  Future<List<MicroPromptResponseModel>> getUserResponsesByCategory(
    String userId,
    String category,
  ) async {
    try {
      debugPrint(
        '🔍 [MICRO PROMPTS] Getting user responses by category for: $userId',
      );

      final response = await _supabase
          .from('user_micro_prompt_responses')
          .select('''
            *,
            micro_prompt_questions!inner(category)
          ''')
          .eq('userId', userId)
          .eq('micro_prompt_questions.category', category)
          .order('responded_at', ascending: false);

      final responses = response
          .map<MicroPromptResponseModel>(
            (json) => MicroPromptResponseModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [MICRO PROMPTS] Found ${responses.length} responses in category',
      );
      return responses;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting responses by category: $e');
      throw Exception('Failed to get responses by category: $e');
    }
  }

  @override
  Future<MicroPromptResponseModel?> getUserResponseForQuestion(
    String userId,
    String questionId,
  ) async {
    try {
      debugPrint(
        '🔍 [MICRO PROMPTS] Getting user response for question: $questionId',
      );

      final response = await _supabase
          .from('user_micro_prompt_responses')
          .select()
          .eq('userId', userId)
          .eq('question_id', questionId)
          .order('responded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [MICRO PROMPTS] User response found');
        return MicroPromptResponseModel.fromJson(response);
      }

      debugPrint('ℹ️ [MICRO PROMPTS] No user response found');
      return null;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting user response: $e');
      throw Exception('Failed to get user response: $e');
    }
  }

  @override
  Future<MicroPromptScheduleModel?> getUserSchedule(String userId) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting user schedule for: $userId');

      final response = await _supabase
          .from('user_micro_prompt_schedule')
          .select()
          .eq('userId', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [MICRO PROMPTS] User schedule found');
        return MicroPromptScheduleModel.fromJson(response);
      }

      debugPrint('ℹ️ [MICRO PROMPTS] No user schedule found');
      return null;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting user schedule: $e');
      throw Exception('Failed to get user schedule: $e');
    }
  }

  @override
  Future<void> saveUserSchedule(MicroPromptScheduleModel schedule) async {
    try {
      debugPrint(
        '💾 [MICRO PROMPTS] Saving user schedule for: ${schedule.userId}',
      );

      await _supabase
          .from('user_micro_prompt_schedule')
          .upsert(schedule.toJson(), onConflict: 'userId');

      debugPrint('✅ [MICRO PROMPTS] User schedule saved successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error saving user schedule: $e');
      throw Exception('Failed to save user schedule: $e');
    }
  }

  @override
  Future<void> updateUserSchedule(MicroPromptScheduleModel schedule) async {
    try {
      debugPrint(
        '🔄 [MICRO PROMPTS] Updating user schedule for: ${schedule.userId}',
      );

      await _supabase
          .from('user_micro_prompt_schedule')
          .update(schedule.toJson())
          .eq('userId', schedule.userId);

      debugPrint('✅ [MICRO PROMPTS] User schedule updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating user schedule: $e');
      throw Exception('Failed to update user schedule: $e');
    }
  }

  @override
  Future<void> updateLastPromptShown(String userId, DateTime timestamp) async {
    try {
      debugPrint('🔄 [MICRO PROMPTS] Updating last prompt shown for: $userId');

      await _supabase
          .from('user_micro_prompt_schedule')
          .update({
            'last_prompt_shown_at': timestamp.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);

      debugPrint('✅ [MICRO PROMPTS] Last prompt shown updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating last prompt shown: $e');
      throw Exception('Failed to update last prompt shown: $e');
    }
  }

  @override
  Future<void> updateNextPromptScheduled(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      debugPrint(
        '🔄 [MICRO PROMPTS] Updating next prompt scheduled for: $userId',
      );

      await _supabase
          .from('user_micro_prompt_schedule')
          .update({
            'next_prompt_scheduled_at': timestamp.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);

      debugPrint(
        '✅ [MICRO PROMPTS] Next prompt scheduled updated successfully',
      );
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating next prompt scheduled: $e');
      throw Exception('Failed to update next prompt scheduled: $e');
    }
  }

  @override
  Future<UserAppStateModel?> getUserAppState(String userId) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting user app state for: $userId');

      final response = await _supabase
          .from('user_app_state')
          .select()
          .eq('userId', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [MICRO PROMPTS] User app state found');
        return UserAppStateModel.fromJson(response);
      }

      debugPrint('ℹ️ [MICRO PROMPTS] No user app state found');
      return null;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting user app state: $e');
      throw Exception('Failed to get user app state: $e');
    }
  }

  @override
  Future<void> saveUserAppState(UserAppStateModel appState) async {
    try {
      debugPrint(
        '💾 [MICRO PROMPTS] Saving user app state for: ${appState.userId}',
      );

      await _supabase
          .from('user_app_state')
          .upsert(appState.toJson(), onConflict: 'userId');

      debugPrint('✅ [MICRO PROMPTS] User app state saved successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error saving user app state: $e');
      throw Exception('Failed to save user app state: $e');
    }
  }

  @override
  Future<void> updateUserAppState(UserAppStateModel appState) async {
    try {
      debugPrint(
        '🔄 [MICRO PROMPTS] Updating user app state for: ${appState.userId}',
      );

      await _supabase
          .from('user_app_state')
          .update(appState.toJson())
          .eq('userId', appState.userId);

      debugPrint('✅ [MICRO PROMPTS] User app state updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating user app state: $e');
      throw Exception('Failed to update user app state: $e');
    }
  }

  @override
  Future<void> updateSensitiveFlowState(
    String userId,
    bool isInSensitiveFlow,
    String? flowType,
  ) async {
    try {
      debugPrint(
        '🔄 [MICRO PROMPTS] Updating sensitive flow state for: $userId',
      );

      await _supabase
          .from('user_app_state')
          .update({
            'is_in_sensitive_flow': isInSensitiveFlow,
            'sensitive_flow_type': flowType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);

      debugPrint('✅ [MICRO PROMPTS] Sensitive flow state updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating sensitive flow state: $e');
      throw Exception('Failed to update sensitive flow state: $e');
    }
  }

  @override
  Future<void> updateCurrentScreen(String userId, String? screenName) async {
    try {
      debugPrint('🔄 [MICRO PROMPTS] Updating current screen for: $userId');

      await _supabase
          .from('user_app_state')
          .update({
            'current_screen': screenName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);

      debugPrint('✅ [MICRO PROMPTS] Current screen updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating current screen: $e');
      throw Exception('Failed to update current screen: $e');
    }
  }

  @override
  Future<void> updateLastActivity(String userId, DateTime timestamp) async {
    try {
      debugPrint('🔄 [MICRO PROMPTS] Updating last activity for: $userId');

      await _supabase
          .from('user_app_state')
          .update({
            'last_activity_at': timestamp.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);

      debugPrint('✅ [MICRO PROMPTS] Last activity updated successfully');
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error updating last activity: $e');
      throw Exception('Failed to update last activity: $e');
    }
  }

  @override
  Future<MicroPromptQuestionModel?> getNextAvailableQuestion(
    String userId,
  ) async {
    try {
      debugPrint(
        '🔍 [MICRO PROMPTS] Getting next available question for: $userId',
      );

      final response = await _supabase
          .from('user_next_micro_prompt')
          .select()
          .eq('userId', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [MICRO PROMPTS] Next available question found');
        return MicroPromptQuestionModel.fromJson({
          'id': response['question_id'],
          'question_text': response['question_text'],
          'category': response['category'],
          'question_order': response['question_order'],
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('ℹ️ [MICRO PROMPTS] No next available question found');
      return null;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting next available question: $e');
      throw Exception('Failed to get next available question: $e');
    }
  }

  @override
  Future<bool> canShowPromptNow(String userId) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Checking if can show prompt for: $userId');

      final schedule = await getUserSchedule(userId);
      final appState = await getUserAppState(userId);

      if (schedule == null || !schedule.isPromptsEnabled) {
        debugPrint('ℹ️ [MICRO PROMPTS] Prompts disabled for user');
        return false;
      }

      if (appState?.isInSensitiveFlow == true) {
        debugPrint('ℹ️ [MICRO PROMPTS] User in sensitive flow');
        return false;
      }

      final now = DateTime.now();

      // Check if it's within quiet hours
      final quietStart = _parseTime(schedule.quietHoursStart);
      final quietEnd = _parseTime(schedule.quietHoursEnd);
      final currentTime = TimeOfDay.fromDateTime(now);

      if (_isInQuietHours(currentTime, quietStart, quietEnd)) {
        debugPrint('ℹ️ [MICRO PROMPTS] Currently in quiet hours');
        return false;
      }

      // Check if enough time has passed since last prompt
      if (schedule.lastPromptShownAt != null) {
        final timeSinceLastPrompt = now.difference(schedule.lastPromptShownAt!);
        debugPrint(
          '🔍 [MICRO PROMPTS] Time check: ${timeSinceLastPrompt.inMinutes} minutes since last prompt, frequency: ${schedule.promptFrequencyMinutes} minutes',
        );

        // If last prompt time is in the future (negative difference), reset it
        if (timeSinceLastPrompt.inMinutes < 0) {
          debugPrint(
            '⚠️ [MICRO PROMPTS] Last prompt time is in future, resetting...',
          );
          await _supabase
              .from('user_micro_prompt_schedule')
              .update({
                'last_prompt_shown_at': null,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('userId', userId);
          debugPrint(
            '✅ [MICRO PROMPTS] Reset last prompt time, allowing prompt to show',
          );
        } else if (timeSinceLastPrompt.inMinutes <
            schedule.promptFrequencyMinutes) {
          debugPrint(
            'ℹ️ [MICRO PROMPTS] Not enough time since last prompt (${timeSinceLastPrompt.inMinutes} < ${schedule.promptFrequencyMinutes})',
          );
          return false;
        }
      }

      debugPrint('✅ [MICRO PROMPTS] Can show prompt now');
      return true;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error checking if can show prompt: $e');
      return false;
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isInQuietHours(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day quiet hours (e.g., 22:00 to 23:59)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight quiet hours (e.g., 23:00 to 07:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfileInsights(String userId) async {
    try {
      debugPrint('📊 [MICRO PROMPTS] Getting profile insights for: $userId');

      final response = await _supabase
          .from('user_micro_prompt_profile')
          .select()
          .eq('userId', userId);

      final insights = <String, dynamic>{};
      for (final row in response) {
        insights[row['category']] = {
          'total_questions': row['total_questions_in_category'],
          'answered_questions': row['answered_questions'],
          'skipped_questions': row['skipped_questions'],
          'ask_later_questions': row['ask_later_questions'],
          'completion_percentage': row['completion_percentage'],
          'responses': row['responses'],
        };
      }

      debugPrint('✅ [MICRO PROMPTS] Profile insights generated');
      return insights;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting profile insights: $e');
      return {};
    }
  }

  @override
  Future<List<MicroPromptQuestionModel>> getUnansweredQuestions(
    String userId,
  ) async {
    try {
      debugPrint(
        '🔍 [MICRO PROMPTS] Getting unanswered questions for: $userId',
      );

      final response = await _supabase.rpc(
        'get_unanswered_questions',
        params: {'user_id': userId},
      );

      final questions = response
          .map<MicroPromptQuestionModel>(
            (json) => MicroPromptQuestionModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [MICRO PROMPTS] Found ${questions.length} unanswered questions',
      );
      return questions;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting unanswered questions: $e');
      throw Exception('Failed to get unanswered questions: $e');
    }
  }

  @override
  Future<List<MicroPromptQuestionModel>> getSkippedQuestions(
    String userId,
  ) async {
    try {
      debugPrint('🔍 [MICRO PROMPTS] Getting skipped questions for: $userId');

      final response = await _supabase
          .from('user_micro_prompt_responses')
          .select('''
            micro_prompt_questions!inner(*)
          ''')
          .eq('userId', userId)
          .eq('response_type', 'skipped')
          .gte(
            'asked_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          );

      final questions = response
          .map<MicroPromptQuestionModel>(
            (json) => MicroPromptQuestionModel.fromJson(
              json['micro_prompt_questions'],
            ),
          )
          .toList();

      debugPrint(
        '✅ [MICRO PROMPTS] Found ${questions.length} skipped questions',
      );
      return questions;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting skipped questions: $e');
      throw Exception('Failed to get skipped questions: $e');
    }
  }

  @override
  Future<int> getUserCompletionPercentage(String userId) async {
    try {
      debugPrint(
        '📊 [MICRO PROMPTS] Getting completion percentage for: $userId',
      );

      final totalQuestions = await getAllQuestions();
      final userResponses = await getUserResponses(userId);

      final answeredCount = userResponses
          .where((response) => response.responseType.value == 'answered')
          .length;

      final percentage = totalQuestions.isNotEmpty
          ? ((answeredCount / totalQuestions.length) * 100).round()
          : 0;

      debugPrint('✅ [MICRO PROMPTS] Completion percentage: $percentage%');
      return percentage;
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS] Error getting completion percentage: $e');
      return 0;
    }
  }
}
