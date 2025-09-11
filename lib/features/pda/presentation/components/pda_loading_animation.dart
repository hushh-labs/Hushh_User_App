import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../../../pda/data/services/pda_preprocessing_manager.dart';

class PdaLoadingAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool isLoading;
  final bool showPreprocessingStatus;

  const PdaLoadingAnimation({
    super.key,
    this.onAnimationComplete,
    required this.isLoading,
    this.showPreprocessingStatus = false,
  });

  @override
  State<PdaLoadingAnimation> createState() => _PdaLoadingAnimationState();
}

class _PdaLoadingAnimationState extends State<PdaLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Preprocessing status
  final PdaPreprocessingManager _preprocessingManager =
      PdaPreprocessingManager();
  StreamSubscription<PreprocessingStatus>? _statusSubscription;
  StreamSubscription<PreprocessingStepStatus>? _stepSubscription;
  PreprocessingStatus? _currentStatus;
  PreprocessingStepStatus? _currentStep;

  @override
  void initState() {
    super.initState();

    // Main animation controller with longer duration to slow down the animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animation with repeat mode to keep it running
    _animationController.repeat();

    // Initialize preprocessing status if needed
    if (widget.showPreprocessingStatus) {
      _initializePreprocessingStatus();
    } else {
      // Set a timer for minimum 1.5 seconds - this is the ONLY thing that should end the animation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          // Minimum time elapsed
          // Always complete after 1.5 seconds, regardless of loading state
          if (widget.onAnimationComplete != null) {
            _animationController.stop();
            widget.onAnimationComplete!();
          }
        }
      });
    }
  }

  void _initializePreprocessingStatus() {
    // Listen to preprocessing status
    _statusSubscription = _preprocessingManager.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });

        _updateProgressAnimation(status.progress);

        if (status.isCompleted) {
          // Complete animation when preprocessing is done
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && widget.onAnimationComplete != null) {
              _animationController.stop();
              widget.onAnimationComplete!();
            }
          });
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

    // Get current status
    _currentStatus = _preprocessingManager.currentStatus;
    if (_currentStatus != null) {
      _updateProgressAnimation(_currentStatus!.progress);
    }
  }

  void _updateProgressAnimation(double progress) {
    _progressController.animateTo(progress);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _statusSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main PDA Animation
          SizedBox(
            width: 350,
            height: 350,
            child: Center(
              child: Lottie.asset(
                'assets/animations/pda.json',
                controller: _animationController,
                onLoaded: (composition) {
                  // Override the duration to make animation slower
                  _animationController.duration = const Duration(
                    milliseconds: 6000,
                  );
                },
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to custom animation if Lottie file is not available
                  return Container(
                    width: 225,
                    height: 225,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA342FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(112.5),
                    ),
                    child: Icon(
                      Icons.psychology_alt_outlined,
                      size: 112,
                      color: const Color(0xFFA342FF),
                    ),
                  );
                },
              ),
            ),
          ),

          // Preprocessing Status (if enabled)
          if (widget.showPreprocessingStatus && _currentStatus != null) ...[
            const SizedBox(height: 32),

            // Current step text
            Text(
              _getCurrentStepText(),
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
              _getCurrentStepDescription(),
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
                        '${_currentStatus!.completedSteps}/${_currentStatus!.totalSteps}',
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
                              color: _currentStatus!.isCompleted
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
          ],
        ],
      ),
    );
  }

  String _getCurrentStepText() {
    if (_currentStatus == null) return 'Preparing PDA...';

    if (_currentStatus!.isCompleted) {
      return 'PDA Ready!';
    }

    // Get current step being processed
    final currentStep = _currentStatus!.steps.firstWhere(
      (step) => step.isInProgress,
      orElse: () => _currentStatus!.steps.lastWhere(
        (step) => step.isCompleted,
        orElse: () => _currentStatus!.steps.first,
      ),
    );

    return currentStep.displayName;
  }

  String _getCurrentStepDescription() {
    if (_currentStatus == null) return 'Loading your data for better responses';

    if (_currentStatus!.isCompleted) {
      return 'All data has been loaded and cached';
    }

    // Get current step being processed
    final currentStep = _currentStatus!.steps.firstWhere(
      (step) => step.isInProgress,
      orElse: () => _currentStatus!.steps.lastWhere(
        (step) => step.isCompleted,
        orElse: () => _currentStatus!.steps.first,
      ),
    );

    return currentStep.description;
  }
}
