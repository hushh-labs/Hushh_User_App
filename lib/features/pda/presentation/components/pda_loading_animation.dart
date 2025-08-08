import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PdaLoadingAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool isLoading; // Add loading state back

  const PdaLoadingAnimation({
    super.key,
    this.onAnimationComplete,
    required this.isLoading,
  });

  @override
  State<PdaLoadingAnimation> createState() => _PdaLoadingAnimationState();
}

class _PdaLoadingAnimationState extends State<PdaLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // Main animation controller with longer duration to slow down the animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    // Start animation with repeat mode to keep it running
    _animationController.repeat();

    // Set a timer for minimum 1.5 seconds - this is the ONLY thing that should end the animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
        // Always complete after 1.5 seconds, regardless of loading state
        if (widget.onAnimationComplete != null) {
          _animationController.stop();
          widget.onAnimationComplete!();
        }
      }
    });
  }

  // Removed _checkAnimationComplete and didUpdateWidget since we only use the timer

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
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
    );
  }
}
