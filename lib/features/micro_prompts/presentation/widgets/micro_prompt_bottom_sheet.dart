import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/micro_prompt_question.dart';
import '../bloc/micro_prompts_bloc.dart';

class MicroPromptBottomSheet extends StatefulWidget {
  final MicroPromptQuestion question;
  final String userId;
  final VoidCallback? onDismiss;

  const MicroPromptBottomSheet({
    super.key,
    required this.question,
    required this.userId,
    this.onDismiss,
  });

  @override
  State<MicroPromptBottomSheet> createState() => _MicroPromptBottomSheetState();
}

class _MicroPromptBottomSheetState extends State<MicroPromptBottomSheet> {
  final TextEditingController _responseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _submitResponse() {
    if (_responseController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    context.read<MicroPromptsBloc>().add(
      SubmitResponse(
        userId: widget.userId,
        questionId: widget.question.id,
        responseText: _responseController.text.trim(),
      ),
    );
  }

  void _skipQuestion() {
    context.read<MicroPromptsBloc>().add(
      SkipQuestion(userId: widget.userId, questionId: widget.question.id),
    );
    // Dismiss the overlay after skipping
    widget.onDismiss?.call();
  }

  void _askLater() {
    context.read<MicroPromptsBloc>().add(
      AskLater(userId: widget.userId, questionId: widget.question.id),
    );
    // Dismiss the overlay after asking later
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MicroPromptsBloc, MicroPromptsState>(
      listener: (context, state) {
        if (state is MicroPromptsResponseSubmitted) {
          // Call the dismiss callback instead of Navigator.pop()
          widget.onDismiss?.call();

          // Show success message if we have a valid context
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.black,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is MicroPromptsError) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question text
              Text(
                widget.question.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.question.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Response input
              TextField(
                controller: _responseController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Answer button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitResponse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Answer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Skip button
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _skipQuestion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ask Later button
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _askLater,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ask Later',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context,
    MicroPromptQuestion question,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<MicroPromptsBloc>(),
        child: MicroPromptBottomSheet(question: question, userId: userId),
      ),
    );
  }
}
