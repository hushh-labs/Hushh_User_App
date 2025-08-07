import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ChatLoadingAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const ChatLoadingAnimation({super.key, this.onAnimationComplete});

  @override
  State<ChatLoadingAnimation> createState() => _ChatLoadingAnimationState();
}

class _ChatLoadingAnimationState extends State<ChatLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // Main animation controller with 1.5 second duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animation
    _animationController.forward();

    // Set a timer for minimum 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
        _checkAnimationComplete();
      }
    });

    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAnimationComplete();
      }
    });
  }

  void _checkAnimationComplete() {
    if (_minimumTimeElapsed && widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 400,
          height: 400,
          child: Center(
            child: Lottie.asset(
              'assets/chat_lottie.json',
              controller: _animationController,
              onLoaded: (composition) {
                // Don't override the duration - keep it at 1.5 seconds minimum
                // _animationController.duration = composition.duration;
              },
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to custom animation if Lottie file is not available
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 150,
                    color: Colors.blue.shade400,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
