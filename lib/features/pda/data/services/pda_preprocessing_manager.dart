import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'gmail_context_prewarm_service.dart';
import 'linkedin_context_prewarm_service.dart';
import 'google_meet_context_prewarm_service.dart';
import 'google_calendar_context_prewarm_service.dart';
import 'prewarming_coordinator_service.dart';
import '../../domain/repositories/gmail_repository.dart';
import '../../domain/repositories/google_meet_repository.dart';
import '../../../vault/data/services/vault_startup_prewarm_service.dart';

/// Enum for different preprocessing steps
enum PreprocessingStep {
  checkingConnections,
  fetchingGmail,
  fetchingLinkedIn,
  fetchingGoogleMeet,
  fetchingGoogleCalendar,
  fetchingVault,
  cachingData,
  prewarmingAI,
  completed,
}

/// Status of a preprocessing step
class PreprocessingStepStatus {
  final PreprocessingStep step;
  final bool isCompleted;
  final bool isInProgress;
  final bool hasError;
  final String? errorMessage;
  final String displayName;
  final String description;

  const PreprocessingStepStatus({
    required this.step,
    required this.isCompleted,
    required this.isInProgress,
    required this.hasError,
    this.errorMessage,
    required this.displayName,
    required this.description,
  });

  PreprocessingStepStatus copyWith({
    bool? isCompleted,
    bool? isInProgress,
    bool? hasError,
    String? errorMessage,
  }) {
    return PreprocessingStepStatus(
      step: step,
      isCompleted: isCompleted ?? this.isCompleted,
      isInProgress: isInProgress ?? this.isInProgress,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      displayName: displayName,
      description: description,
    );
  }
}

/// Overall preprocessing status
class PreprocessingStatus {
  final bool isCompleted;
  final bool isInProgress;
  final List<PreprocessingStepStatus> steps;
  final int completedSteps;
  final int totalSteps;
  final double progress; // 0.0 to 1.0

  const PreprocessingStatus({
    required this.isCompleted,
    required this.isInProgress,
    required this.steps,
    required this.completedSteps,
    required this.totalSteps,
    required this.progress,
  });
}

/// Centralized manager for PDA preprocessing
class PdaPreprocessingManager {
  static final PdaPreprocessingManager _instance =
      PdaPreprocessingManager._internal();
  factory PdaPreprocessingManager() => _instance;
  PdaPreprocessingManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  final PrewarmingCoordinatorService _coordinator =
      PrewarmingCoordinatorService();

  // Stream controllers for real-time updates
  final StreamController<PreprocessingStatus> _statusController =
      StreamController<PreprocessingStatus>.broadcast();
  final StreamController<PreprocessingStepStatus> _stepController =
      StreamController<PreprocessingStepStatus>.broadcast();

  // Current status
  PreprocessingStatus? _currentStatus;
  bool _isPreprocessing = false;
  bool _isCompleted = false;

  // Getters for streams
  Stream<PreprocessingStatus> get statusStream => _statusController.stream;
  Stream<PreprocessingStepStatus> get stepStream => _stepController.stream;

  // Getter for current status
  PreprocessingStatus? get currentStatus => _currentStatus;
  bool get isPreprocessing => _isPreprocessing;
  bool get isCompleted => _isCompleted;

  // Define all preprocessing steps
  static const List<PreprocessingStepStatus> _initialSteps = [
    PreprocessingStepStatus(
      step: PreprocessingStep.checkingConnections,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Checking Connections',
      description: 'Verifying connected accounts and services',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.fetchingGmail,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Fetching Gmail Data',
      description: 'Loading your email context',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.fetchingLinkedIn,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Fetching LinkedIn Data',
      description: 'Loading your professional context',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.fetchingGoogleMeet,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Fetching Google Meet Data',
      description: 'Loading your meeting history',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.fetchingGoogleCalendar,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Fetching Calendar Data',
      description: 'Loading your calendar events',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.fetchingVault,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Fetching Vault Data',
      description: 'Loading your documents',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.cachingData,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Caching Data',
      description: 'Storing data for faster access',
    ),
    PreprocessingStepStatus(
      step: PreprocessingStep.prewarmingAI,
      isCompleted: false,
      isInProgress: false,
      hasError: false,
      displayName: 'Prewarming AI',
      description: 'Preparing AI context for better responses',
    ),
  ];

  /// Start the complete preprocessing flow
  Future<void> startPreprocessing() async {
    if (_isPreprocessing) {
      debugPrint('🔄 [PDA PREPROCESSING] Already in progress, skipping');
      return;
    }

    if (_isCompleted) {
      debugPrint('✅ [PDA PREPROCESSING] Already completed, skipping');
      return;
    }

    // Check if app startup prewarming processes are running or completed
    final processStatus = _coordinator.getProcessStatus();
    final isAppPrewarmingRunning =
        processStatus.containsKey('pda_prewarm') ||
        processStatus.containsKey('pda_vertex_ai_prewarm') ||
        processStatus.containsKey('gmail_prewarm') ||
        processStatus.containsKey('linkedin_prewarm') ||
        processStatus.containsKey('google_calendar_prewarm') ||
        processStatus.containsKey('document_prewarm') ||
        processStatus.containsKey('google_meet_prewarm') ||
        processStatus.containsKey('vault_prewarm');

    if (isAppPrewarmingRunning) {
      debugPrint(
        '🔄 [PDA PREPROCESSING] App startup prewarming in progress, monitoring progress...',
      );
      _isPreprocessing = true;

      // Initialize status to show we're monitoring app prewarming
      _updateStatus(
        PreprocessingStatus(
          isCompleted: false,
          isInProgress: true,
          steps: List.from(_initialSteps),
          completedSteps: 0,
          totalSteps: _initialSteps.length,
          progress: 0.0,
        ),
      );

      try {
        // Monitor app prewarming progress in real-time
        await _monitorAppPrewarmingProgress();

        // Mark all steps as completed since app prewarming handles everything
        _isCompleted = true;
        _updateStatus(
          PreprocessingStatus(
            isCompleted: true,
            isInProgress: false,
            steps: _initialSteps
                .map(
                  (step) =>
                      step.copyWith(isCompleted: true, isInProgress: false),
                )
                .toList(),
            completedSteps: _initialSteps.length,
            totalSteps: _initialSteps.length,
            progress: 1.0,
          ),
        );

        debugPrint(
          '✅ [PDA PREPROCESSING] App startup prewarming completed, PDA ready',
        );
      } catch (e) {
        debugPrint('❌ [PDA PREPROCESSING] Error monitoring app prewarming: $e');
        _markCurrentStepAsError(e.toString());
      } finally {
        _isPreprocessing = false;
      }
      return;
    }

    try {
      _isPreprocessing = true;
      debugPrint('🚀 [PDA PREPROCESSING] Starting complete preprocessing flow');

      // Initialize status with all steps
      _updateStatus(
        PreprocessingStatus(
          isCompleted: false,
          isInProgress: true,
          steps: List.from(_initialSteps),
          completedSteps: 0,
          totalSteps: _initialSteps.length,
          progress: 0.0,
        ),
      );

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Check connections
      await _executeStep(PreprocessingStep.checkingConnections, () async {
        await _checkAllConnections();
      });

      // Step 2: Fetch Gmail data (if connected)
      await _executeStep(PreprocessingStep.fetchingGmail, () async {
        await _fetchGmailData();
      });

      // Step 3: Fetch LinkedIn data (if connected)
      await _executeStep(PreprocessingStep.fetchingLinkedIn, () async {
        await _fetchLinkedInData();
      });

      // Step 4: Fetch Google Meet data (if connected)
      await _executeStep(PreprocessingStep.fetchingGoogleMeet, () async {
        await _fetchGoogleMeetData();
      });

      // Step 5: Fetch Google Calendar data (if connected)
      await _executeStep(PreprocessingStep.fetchingGoogleCalendar, () async {
        await _fetchGoogleCalendarData();
      });

      // Step 6: Fetch Vault data
      await _executeStep(PreprocessingStep.fetchingVault, () async {
        await _fetchVaultData();
      });

      // Step 7: Cache all data
      await _executeStep(PreprocessingStep.cachingData, () async {
        await _cacheAllData();
      });

      // Step 8: Prewarm AI
      await _executeStep(PreprocessingStep.prewarmingAI, () async {
        await _prewarmAI();
      });

      // Mark as completed
      _isCompleted = true;
      _updateStatus(
        PreprocessingStatus(
          isCompleted: true,
          isInProgress: false,
          steps: _currentStatus!.steps
              .map(
                (step) => step.copyWith(isCompleted: true, isInProgress: false),
              )
              .toList(),
          completedSteps: _initialSteps.length,
          totalSteps: _initialSteps.length,
          progress: 1.0,
        ),
      );

      debugPrint(
        '✅ [PDA PREPROCESSING] Complete preprocessing flow finished successfully',
      );
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Error during preprocessing: $e');
      _markCurrentStepAsError(e.toString());
    } finally {
      _isPreprocessing = false;
    }
  }

  /// Execute a single preprocessing step
  Future<void> _executeStep(
    PreprocessingStep step,
    Future<void> Function() action,
  ) async {
    try {
      // Mark step as in progress
      _updateStepStatus(step, isInProgress: true);

      // Execute the action
      await action();

      // Mark step as completed
      _updateStepStatus(step, isCompleted: true, isInProgress: false);
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Error in step ${step.name}: $e');
      _updateStepStatus(
        step,
        hasError: true,
        isInProgress: false,
        errorMessage: e.toString(),
      );
      // Continue with next steps even if one fails
    }
  }

  /// Check all service connections
  Future<void> _checkAllConnections() async {
    debugPrint('🔍 [PDA PREPROCESSING] Checking all connections...');

    try {
      final gmailRepo = _getIt<GmailRepository>();
      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final user = _auth.currentUser!;

      // Check connections in parallel
      await Future.wait([
        gmailRepo.isGmailConnected(user.uid),
        googleMeetRepo.isGoogleMeetConnected(user.uid),
        // Add other connection checks here
      ]);

      debugPrint('✅ [PDA PREPROCESSING] Connection check completed');
    } catch (e) {
      debugPrint('⚠️ [PDA PREPROCESSING] Some connections failed to check: $e');
      // Don't throw error, continue with available services
    }
  }

  /// Fetch Gmail data
  Future<void> _fetchGmailData() async {
    try {
      final gmailService = GmailContextPrewarmService();
      final isConnected = await gmailService.isGmailConnected();

      if (isConnected) {
        debugPrint('📧 [PDA PREPROCESSING] Fetching Gmail data...');
        await gmailService.prewarmGmailContext();
        debugPrint('✅ [PDA PREPROCESSING] Gmail data fetched successfully');
      } else {
        debugPrint('ℹ️ [PDA PREPROCESSING] Gmail not connected, skipping');
      }
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Gmail fetch failed: $e');
      throw e;
    }
  }

  /// Fetch LinkedIn data
  Future<void> _fetchLinkedInData() async {
    try {
      final linkedInService = LinkedInContextPrewarmService();
      final isConnected = await linkedInService.isLinkedInConnected();

      if (isConnected) {
        debugPrint('💼 [PDA PREPROCESSING] Fetching LinkedIn data...');
        await linkedInService.prewarmLinkedInContext();
        debugPrint('✅ [PDA PREPROCESSING] LinkedIn data fetched successfully');
      } else {
        debugPrint('ℹ️ [PDA PREPROCESSING] LinkedIn not connected, skipping');
      }
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] LinkedIn fetch failed: $e');
      throw e;
    }
  }

  /// Fetch Google Meet data
  Future<void> _fetchGoogleMeetData() async {
    try {
      final googleMeetService = GoogleMeetContextPrewarmService();
      final isConnected = await googleMeetService.isGoogleMeetConnected();

      if (isConnected) {
        debugPrint('📹 [PDA PREPROCESSING] Fetching Google Meet data...');
        await googleMeetService.prewarmGoogleMeetContext();
        debugPrint(
          '✅ [PDA PREPROCESSING] Google Meet data fetched successfully',
        );
      } else {
        debugPrint(
          'ℹ️ [PDA PREPROCESSING] Google Meet not connected, skipping',
        );
      }
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Google Meet fetch failed: $e');
      throw e;
    }
  }

  /// Fetch Google Calendar data
  Future<void> _fetchGoogleCalendarData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('ℹ️ [PDA PREPROCESSING] No user, skipping Google Calendar');
        return;
      }

      // Check if Google Meet is connected (Calendar data comes through Google Meet sync)
      final googleMeetService = GoogleMeetContextPrewarmService();
      final isConnected = await googleMeetService.isGoogleMeetConnected();

      if (isConnected) {
        debugPrint('📅 [PDA PREPROCESSING] Fetching Google Calendar data...');

        // Get calendar service from GetIt if available
        try {
          final calendarService = _getIt<GoogleCalendarContextPrewarmService>();
          await calendarService.prewarmOnStartup(user.uid);
          debugPrint(
            '✅ [PDA PREPROCESSING] Google Calendar data fetched successfully',
          );
        } catch (getItError) {
          debugPrint(
            'ℹ️ [PDA PREPROCESSING] Calendar service not registered, skipping',
          );
        }
      } else {
        debugPrint(
          'ℹ️ [PDA PREPROCESSING] Google Calendar not connected, skipping',
        );
      }
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Google Calendar fetch failed: $e');
      // Don't throw error, continue with other services
    }
  }

  /// Fetch Vault data
  Future<void> _fetchVaultData() async {
    try {
      final vaultService = _getIt<VaultStartupPrewarmService>();
      debugPrint('🗄️ [PDA PREPROCESSING] Fetching Vault data...');
      await vaultService.prewarmVaultOnStartup();
      debugPrint('✅ [PDA PREPROCESSING] Vault data fetched successfully');
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Vault fetch failed: $e');
      throw e;
    }
  }

  /// Cache all data
  Future<void> _cacheAllData() async {
    try {
      debugPrint('💾 [PDA PREPROCESSING] Caching all data...');
      // Data is already cached by individual services
      // This step is for any additional caching logic
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate caching
      debugPrint('✅ [PDA PREPROCESSING] Data caching completed');
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] Data caching failed: $e');
      throw e;
    }
  }

  /// Prewarm AI
  Future<void> _prewarmAI() async {
    try {
      debugPrint('🧠 [PDA PREPROCESSING] Prewarming AI context...');
      // AI context is already prewarmed by individual services
      // This step is for any additional AI preparation
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate AI prewarming
      debugPrint('✅ [PDA PREPROCESSING] AI prewarming completed');
    } catch (e) {
      debugPrint('❌ [PDA PREPROCESSING] AI prewarming failed: $e');
      throw e;
    }
  }

  /// Update the overall status
  void _updateStatus(PreprocessingStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Update a specific step status
  void _updateStepStatus(
    PreprocessingStep step, {
    bool? isCompleted,
    bool? isInProgress,
    bool? hasError,
    String? errorMessage,
  }) {
    if (_currentStatus == null) return;

    final updatedSteps = _currentStatus!.steps.map((stepStatus) {
      if (stepStatus.step == step) {
        final updated = stepStatus.copyWith(
          isCompleted: isCompleted,
          isInProgress: isInProgress,
          hasError: hasError,
          errorMessage: errorMessage,
        );
        _stepController.add(updated);
        return updated;
      }
      return stepStatus;
    }).toList();

    final completedCount = updatedSteps.where((s) => s.isCompleted).length;
    final progress = completedCount / updatedSteps.length;

    _updateStatus(
      PreprocessingStatus(
        isCompleted: completedCount == updatedSteps.length,
        isInProgress: _isPreprocessing,
        steps: updatedSteps,
        completedSteps: completedCount,
        totalSteps: updatedSteps.length,
        progress: progress,
      ),
    );
  }

  /// Mark current step as error
  void _markCurrentStepAsError(String errorMessage) {
    if (_currentStatus == null) return;

    final currentStep = _currentStatus!.steps.firstWhere(
      (step) => step.isInProgress,
      orElse: () => _currentStatus!.steps.last,
    );

    _updateStepStatus(
      currentStep.step,
      hasError: true,
      isInProgress: false,
      errorMessage: errorMessage,
    );
  }

  /// Monitor app prewarming progress in real-time
  Future<void> _monitorAppPrewarmingProgress() async {
    debugPrint(
      '🔍 [PDA PREPROCESSING] Starting to monitor app prewarming progress...',
    );

    // Map of process names to preprocessing steps
    final processToStepMap = {
      'gmail_prewarm': PreprocessingStep.fetchingGmail,
      'linkedin_prewarm': PreprocessingStep.fetchingLinkedIn,
      'google_meet_prewarm': PreprocessingStep.fetchingGoogleMeet,
      'google_calendar_prewarm': PreprocessingStep.fetchingGoogleCalendar,
      'document_prewarm': PreprocessingStep.fetchingVault,
      'vault_prewarm': PreprocessingStep.fetchingVault,
    };

    // Start with checking connections
    _updateStepStatus(
      PreprocessingStep.checkingConnections,
      isInProgress: true,
    );
    await Future.delayed(const Duration(milliseconds: 200));
    _updateStepStatus(
      PreprocessingStep.checkingConnections,
      isCompleted: true,
      isInProgress: false,
    );

    // Monitor each process
    final processesToMonitor = processToStepMap.keys.toList();
    int completedProcesses = 0;

    while (completedProcesses < processesToMonitor.length) {
      final currentProcessStatus = _coordinator.getProcessStatus();

      for (final processName in processesToMonitor) {
        final step = processToStepMap[processName];
        if (step == null) continue;

        final isRunning = currentProcessStatus.containsKey(processName);
        final currentStepStatus = _currentStatus?.steps.firstWhere(
          (s) => s.step == step,
          orElse: () => _initialSteps.firstWhere((s) => s.step == step),
        );

        if (isRunning &&
            !currentStepStatus!.isInProgress &&
            !currentStepStatus.isCompleted) {
          // Process is running but step not marked as in progress
          debugPrint('🔄 [PDA PREPROCESSING] Starting step: ${step.name}');
          _updateStepStatus(step, isInProgress: true);
        } else if (!isRunning && currentStepStatus!.isInProgress) {
          // Process completed
          debugPrint('✅ [PDA PREPROCESSING] Completed step: ${step.name}');
          _updateStepStatus(step, isCompleted: true, isInProgress: false);
          completedProcesses++;
        }
      }

      // Check if all processes are done
      if (currentProcessStatus.isEmpty) {
        // All processes completed
        break;
      }

      // Wait a bit before checking again
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Mark remaining steps as completed
    for (final step in [
      PreprocessingStep.cachingData,
      PreprocessingStep.prewarmingAI,
    ]) {
      _updateStepStatus(step, isInProgress: true);
      await Future.delayed(const Duration(milliseconds: 200));
      _updateStepStatus(step, isCompleted: true, isInProgress: false);
    }

    debugPrint('✅ [PDA PREPROCESSING] App prewarming monitoring completed');
  }

  /// Check if preprocessing is required
  Future<bool> isPreprocessingRequired() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if app startup prewarming is running or completed
      final processStatus = _coordinator.getProcessStatus();
      final isAppPrewarmingRunning =
          processStatus.containsKey('pda_prewarm') ||
          processStatus.containsKey('pda_vertex_ai_prewarm') ||
          processStatus.containsKey('gmail_prewarm') ||
          processStatus.containsKey('linkedin_prewarm') ||
          processStatus.containsKey('google_calendar_prewarm') ||
          processStatus.containsKey('document_prewarm') ||
          processStatus.containsKey('google_meet_prewarm') ||
          processStatus.containsKey('vault_prewarm');

      // If app startup prewarming is running, we need to show progress
      if (isAppPrewarmingRunning) {
        debugPrint(
          '🔄 [PDA PREPROCESSING] App startup prewarming in progress, showing progress',
        );
        return true;
      }

      // Check if prewarming was already completed by checking if we have cached data
      final gmailService = GmailContextPrewarmService();
      final googleMeetService = GoogleMeetContextPrewarmService();

      final isGmailConnected = await gmailService.isGmailConnected();
      final isGoogleMeetConnected = await googleMeetService
          .isGoogleMeetConnected();

      // If services are connected, check if we have cached data
      if (isGmailConnected || isGoogleMeetConnected) {
        // Check if we have cached PDA context (indicating prewarming was completed)
        final doc = await FirebaseFirestore.instance
            .collection('HushUsers')
            .doc(user.uid)
            .collection('pda_context')
            .doc('gmail')
            .get();

        if (doc.exists) {
          debugPrint(
            '✅ [PDA PREPROCESSING] Prewarming already completed, skipping',
          );
          _isCompleted = true;
          return false; // No preprocessing needed
        }
      }

      // If any service is connected but no cached data, preprocessing is required
      return isGmailConnected || isGoogleMeetConnected;
    } catch (e) {
      debugPrint(
        '❌ [PDA PREPROCESSING] Error checking if preprocessing required: $e',
      );
      return true; // Default to requiring preprocessing
    }
  }

  /// Reset preprocessing status
  void reset() {
    _isPreprocessing = false;
    _isCompleted = false;
    _currentStatus = null;
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _stepController.close();
  }
}
