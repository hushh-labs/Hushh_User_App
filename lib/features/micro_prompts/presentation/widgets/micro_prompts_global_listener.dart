import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_router.dart';
import '../bloc/micro_prompts_bloc.dart';
import 'micro_prompt_bottom_sheet.dart';

/// Global listener widget that shows micro-prompt bottom sheets
/// when questions are loaded through the BLoC
class MicroPromptsGlobalListener extends StatelessWidget {
  final Widget child;

  const MicroPromptsGlobalListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MicroPromptsBloc, MicroPromptsState>(
      listener: (context, state) {
        if (state is MicroPromptsQuestionLoaded) {
          // Show the micro-prompt bottom sheet when a question is loaded
          _showMicroPromptBottomSheet(context, state);
        }
      },
      child: child,
    );
  }

  void _showMicroPromptBottomSheet(
    BuildContext context,
    MicroPromptsQuestionLoaded state, [
    int retryCount = 0,
  ]) {
    // Maximum retries before using overlay approach
    const maxRetries = 5;

    // Wait longer initially to ensure app is ready
    final delay = retryCount == 0
        ? const Duration(seconds: 15) // Wait 15 seconds on first attempt
        : const Duration(seconds: 3); // Subsequent attempts wait 3 seconds

    Future.delayed(delay, () {
      // Try to use the navigator state directly from the global key
      final navigatorState = AppRouter.navigatorKey.currentState;

      if (navigatorState != null) {
        try {
          print(
            '🎯 [MICRO PROMPTS] Attempting to show bottom sheet with navigator state',
          );

          // Create an overlay entry as a fallback that doesn't need MaterialLocalizations
          late OverlayEntry overlayEntry;

          overlayEntry = OverlayEntry(
            builder: (overlayContext) => Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // Backdrop
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        // Remove overlay when tapped outside
                        overlayEntry.remove();
                      },
                      child: Container(color: Colors.black54),
                    ),
                  ),
                  // Bottom sheet content
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            MediaQuery.of(context).size.height * value,
                          ),
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (KeyEvent event) {
                              // Handle Escape key to dismiss the overlay
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.escape) {
                                overlayEntry.remove();
                              }
                            },
                            child: BlocProvider.value(
                              value: context.read<MicroPromptsBloc>(),
                              child: MicroPromptBottomSheet(
                                question: state.question,
                                userId: state.userId,
                                onDismiss: () {
                                  // Remove the overlay when dismissed
                                  overlayEntry.remove();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );

          // Try to insert the overlay
          navigatorState.overlay?.insert(overlayEntry);
          print('✅ [MICRO PROMPTS] Bottom sheet displayed using overlay!');

          // Set up removal after user interaction
          Future.delayed(const Duration(seconds: 30), () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          });

          return; // Success!
        } catch (e) {
          print('❌ [MICRO PROMPTS] Error with overlay approach: $e');
        }
      }

      // If we haven't succeeded and haven't exceeded max retries, try again
      if (retryCount < maxRetries) {
        print(
          '🔄 [MICRO PROMPTS] Navigator not ready, retrying... (attempt ${retryCount + 2}/${maxRetries + 1})',
        );
        _showMicroPromptBottomSheet(context, state, retryCount + 1);
      } else {
        // Final fallback - use a simple dialog without Material widgets
        print('🚨 [MICRO PROMPTS] Using final fallback approach...');
        Future.delayed(const Duration(seconds: 5), () {
          _showSimpleFallbackPrompt(context, state);
        });
      }
    });
  }

  // Simple fallback that doesn't require MaterialLocalizations
  void _showSimpleFallbackPrompt(
    BuildContext context,
    MicroPromptsQuestionLoaded state,
  ) {
    try {
      final navigatorState = AppRouter.navigatorKey.currentState;
      if (navigatorState != null) {
        navigatorState.push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            pageBuilder: (_, __, ___) => WillPopScope(
              onWillPop: () async => true,
              child: GestureDetector(
                onTap: () => navigatorState.pop(),
                child: Container(
                  color: Colors.black54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: BlocProvider.value(
                      value: context.read<MicroPromptsBloc>(),
                      child: MicroPromptBottomSheet(
                        question: state.question,
                        userId: state.userId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        print('✅ [MICRO PROMPTS] Fallback prompt displayed!');
      }
    } catch (e) {
      print('💀 [MICRO PROMPTS] All attempts failed: $e');
    }
  }
}
