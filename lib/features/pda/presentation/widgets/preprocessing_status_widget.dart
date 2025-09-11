import 'package:flutter/material.dart';
import 'dart:async';

import '../../data/services/pda_preprocessing_manager.dart';
import '../components/pda_loading_animation.dart';

/// Widget to display preprocessing status with live updates
class PreprocessingStatusWidget extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool showAsOverlay;

  const PreprocessingStatusWidget({
    super.key,
    this.onCompleted,
    this.showAsOverlay = false,
  });

  @override
  State<PreprocessingStatusWidget> createState() =>
      _PreprocessingStatusWidgetState();
}

class _PreprocessingStatusWidgetState extends State<PreprocessingStatusWidget>
    with TickerProviderStateMixin {
  final PdaPreprocessingManager _preprocessingManager =
      PdaPreprocessingManager();

  StreamSubscription<PreprocessingStatus>? _statusSubscription;
  StreamSubscription<PreprocessingStepStatus>? _stepSubscription;

  PreprocessingStatus? _currentStatus;
  PreprocessingStepStatus? _currentStep;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Listen to preprocessing status
    _listenToPreprocessingStatus();

    // Get current status
    _currentStatus = _preprocessingManager.currentStatus;
    if (_currentStatus != null) {
      _updateProgressAnimation(_currentStatus!.progress);
    }
  }

  void _listenToPreprocessingStatus() {
    _statusSubscription = _preprocessingManager.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });

        _updateProgressAnimation(status.progress);

        if (status.isCompleted) {
          widget.onCompleted?.call();
        }
      }
    });

    _stepSubscription = _preprocessingManager.stepStream.listen((step) {
      if (mounted) {
        setState(() {
          _currentStep = step;
        });
      }
    });
  }

  void _updateProgressAnimation(double progress) {
    _progressController.animateTo(progress);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _stepSubscription?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return const SizedBox.shrink();
    }

    return _buildCleanPreprocessingUI();
  }

  Widget _buildCleanPreprocessingUI() {
    final status = _currentStatus!;

    // Get current step being processed
    final currentStep = status.steps.firstWhere(
      (step) => step.isInProgress,
      orElse: () => status.steps.lastWhere(
        (step) => step.isCompleted,
        orElse: () => status.steps.first,
      ),
    );

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PDA Loading Animation
          PdaLoadingAnimation(
            isLoading: !status.isCompleted,
            onAnimationComplete: () {},
          ),

          const SizedBox(height: 32),

          // Current step text
          Text(
            status.isCompleted ? 'PDA Ready!' : currentStep.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Current step description
          Text(
            status.isCompleted
                ? 'All data has been loaded and cached'
                : currentStep.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Progress bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${status.completedSteps}/${status.totalSteps}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: status.isCompleted
                                ? Colors.green
                                : const Color(0xFFA342FF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// Simple loading indicator for preprocessing
class PreprocessingLoadingIndicator extends StatelessWidget {
  final String message;

  const PreprocessingLoadingIndicator({
    super.key,
    this.message = 'Preparing PDA...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
