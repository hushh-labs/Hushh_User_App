import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/micro_prompts_repository.dart';
import '../../presentation/bloc/micro_prompts_bloc.dart';

class MicroPromptsSchedulerService {
  final MicroPromptsRepository _repository;
  Timer? _schedulerTimer;
  String? _currentUserId;
  MicroPromptsBloc? _bloc;

  MicroPromptsSchedulerService(this._repository);

  /// Initialize the scheduler for a specific user
  void initialize(String userId, MicroPromptsBloc bloc) {
    debugPrint('🔄 [MICRO PROMPTS SCHEDULER] Initializing for user: $userId');

    _currentUserId = userId;
    _bloc = bloc;

    // Initialize user schedule if needed using BLoC
    _bloc?.add(InitializeUserSchedule(userId));

    // Start the periodic check
    _startPeriodicCheck();
  }

  /// Start the periodic check timer (every 30 minutes in production)
  void _startPeriodicCheck() {
    _schedulerTimer?.cancel();

    _schedulerTimer = Timer.periodic(
      const Duration(minutes: 30),
      (timer) => _checkAndShowPrompt(),
    );

    // Delay the first check significantly to ensure app is fully initialized
    Future.delayed(const Duration(seconds: 10), () {
      _checkAndShowPrompt();
    });
  }

  /// Check if we should show a prompt and trigger BLoC event if conditions are met
  Future<void> _checkAndShowPrompt() async {
    if (_currentUserId == null || _bloc == null) return;

    try {
      debugPrint('🔍 [MICRO PROMPTS SCHEDULER] Checking if can show prompt');

      // Use BLoC to load next question, which will handle all the logic
      _bloc!.add(LoadNextQuestion(_currentUserId!));
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS SCHEDULER] Error checking prompt: $e');
    }
  }

  /// Update user's sensitive flow state
  void updateSensitiveFlow(
    String userId,
    bool isInSensitiveFlow,
    String? flowType,
  ) {
    if (_currentUserId != userId) return;

    debugPrint(
      '🔄 [MICRO PROMPTS SCHEDULER] Updating sensitive flow: $isInSensitiveFlow',
    );

    try {
      _repository.updateSensitiveFlowState(
        userId,
        isInSensitiveFlow,
        flowType != null ? _parseFlowType(flowType) : null,
      );
    } catch (e) {
      debugPrint(
        '❌ [MICRO PROMPTS SCHEDULER] Error updating sensitive flow: $e',
      );
    }
  }

  /// Update user's current screen
  void updateCurrentScreen(String userId, String? screenName) {
    if (_currentUserId != userId) return;

    try {
      _repository.updateCurrentScreen(userId, screenName);
      _repository.updateLastActivity(userId, DateTime.now());
    } catch (e) {
      debugPrint('❌ [MICRO PROMPTS SCHEDULER] Error updating screen: $e');
    }
  }

  /// Parse flow type string to enum
  dynamic _parseFlowType(String flowType) {
    switch (flowType.toLowerCase()) {
      case 'login':
        return 'login';
      case 'onboarding':
        return 'onboarding';
      case 'upload':
        return 'upload';
      case 'payment':
        return 'payment';
      default:
        return null;
    }
  }

  /// Manually trigger a prompt check (useful for testing)
  Future<void> triggerPromptCheck() async {
    debugPrint('🔄 [MICRO PROMPTS SCHEDULER] Manual trigger requested');
    await _checkAndShowPrompt();
  }

  /// Pause the scheduler (e.g., when app goes to background)
  void pause() {
    debugPrint('⏸️ [MICRO PROMPTS SCHEDULER] Pausing scheduler');
    _schedulerTimer?.cancel();
  }

  /// Resume the scheduler (e.g., when app comes to foreground)
  void resume() {
    if (_currentUserId != null) {
      debugPrint('▶️ [MICRO PROMPTS SCHEDULER] Resuming scheduler');
      _startPeriodicCheck();
    }
  }

  /// Stop the scheduler and clean up
  void dispose() {
    debugPrint('🛑 [MICRO PROMPTS SCHEDULER] Disposing scheduler');
    _schedulerTimer?.cancel();
    _currentUserId = null;
    _bloc = null;
  }

  /// Update the BLoC reference
  void updateBloc(MicroPromptsBloc bloc) {
    _bloc = bloc;
  }

  /// Check if scheduler is active
  bool get isActive => _schedulerTimer?.isActive ?? false;

  /// Get current user ID
  String? get currentUserId => _currentUserId;
}

/// Singleton instance for global access
class MicroPromptsScheduler {
  static MicroPromptsSchedulerService? _instance;

  static void initialize(MicroPromptsRepository repository) {
    _instance = MicroPromptsSchedulerService(repository);
  }

  static MicroPromptsSchedulerService get instance {
    if (_instance == null) {
      throw Exception(
        'MicroPromptsScheduler not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;
}
