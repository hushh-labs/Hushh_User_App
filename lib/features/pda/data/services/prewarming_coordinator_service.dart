import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service to coordinate prewarming processes and prevent duplicates
class PrewarmingCoordinatorService {
  static final PrewarmingCoordinatorService _instance =
      PrewarmingCoordinatorService._internal();
  factory PrewarmingCoordinatorService() => _instance;
  PrewarmingCoordinatorService._internal();

  // Track running prewarming processes
  final Set<String> _runningProcesses = <String>{};
  final Map<String, Completer<void>> _processCompleters =
      <String, Completer<void>>{};

  /// Check if a prewarming process is already running
  bool isProcessRunning(String processName) {
    return _runningProcesses.contains(processName);
  }

  /// Start a prewarming process if not already running
  Future<void> startProcess(
    String processName,
    Future<void> Function() processFunction,
  ) async {
    // If process is already running, wait for it to complete
    if (_runningProcesses.contains(processName)) {
      debugPrint(
        '🔄 [PREWARMING COORDINATOR] Process $processName already running, waiting for completion...',
      );
      return _processCompleters[processName]?.future ?? Future.value();
    }

    // Mark process as running
    _runningProcesses.add(processName);
    final completer = Completer<void>();
    _processCompleters[processName] = completer;

    debugPrint('🚀 [PREWARMING COORDINATOR] Starting process: $processName');

    try {
      // Execute the process
      await processFunction();
      debugPrint('✅ [PREWARMING COORDINATOR] Process completed: $processName');
    } catch (e) {
      debugPrint(
        '❌ [PREWARMING COORDINATOR] Process failed: $processName - $e',
      );
      rethrow;
    } finally {
      // Clean up
      _runningProcesses.remove(processName);
      _processCompleters.remove(processName);
      completer.complete();
    }
  }

  /// Wait for a specific process to complete
  Future<void> waitForProcess(String processName) async {
    if (_processCompleters.containsKey(processName)) {
      return _processCompleters[processName]!.future;
    }
    return Future.value();
  }

  /// Wait for all processes to complete
  Future<void> waitForAllProcesses() async {
    if (_processCompleters.isEmpty) {
      return Future.value();
    }

    final futures = _processCompleters.values.map(
      (completer) => completer.future,
    );
    await Future.wait(futures);
  }

  /// Cancel all running processes
  void cancelAllProcesses() {
    debugPrint('🛑 [PREWARMING COORDINATOR] Cancelling all processes');
    _runningProcesses.clear();
    for (final completer in _processCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _processCompleters.clear();
  }

  /// Get status of all processes
  Map<String, bool> getProcessStatus() {
    final status = <String, bool>{};
    for (final process in _runningProcesses) {
      status[process] = true;
    }
    return status;
  }
}
