import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/qna_bloc.dart';
import '../../domain/entities/question.dart';

class QnAPage extends StatefulWidget {
  final String agentId;
  final String agentName;

  const QnAPage({super.key, required this.agentId, required this.agentName});

  @override
  State<QnAPage> createState() => _QnAPageState();
}

class _QnAPageState extends State<QnAPage> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<QnABloc>().add(
      StartQnASessionEvent(
        agentId: widget.agentId,
        agentName: widget.agentName,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Widget _buildQuestionContent(
    BuildContext context,
    Question question,
    int currentStep,
    int totalSteps,
    bool isLastQuestion,
    bool isSubmitting,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentStep / totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Personal matching tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PERSONAL MATCHING',
                style: TextStyle(
                  color: Color(0xFF1D1D1F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Question title
          Center(
            child: Text(
              question.text,
              style: const TextStyle(
                color: Color(0xFF1D1D1F),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          const Center(
            child: Text(
              'Help us match you with the perfect concierge',
              style: TextStyle(
                color: Color(0xFF6E6E73),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),

          // Question content
          if (question.type == QuestionType.multipleChoice)
            _buildMultipleChoiceOptions(question, isSubmitting)
          else
            _buildTextInput(question, isSubmitting),

          const SizedBox(height: 48),

          // Bottom tag
          const Center(
            child: Text(
              'Tailored luxury recommendations',
              style: TextStyle(
                color: Color(0xFF6E6E73),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          BlocBuilder<QnABloc, QnAState>(
            builder: (context, state) {
              if (state is QnASessionActive) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.currentQuestionIndex + 1} of ${state.session.questions.length}',
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<QnABloc, QnAState>(
        listener: (context, state) {
          if (state is QnAError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is QnASessionCompleted) {
            // Navigate to results or next page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you! Your preferences have been saved.'),
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is QnALoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D1D1F)),
            );
          }

          if (state is QnASessionActive) {
            // Safety check to prevent RangeError
            if (state.currentQuestionIndex >= state.session.questions.length) {
              return const Center(
                child: Text(
                  'Error: Question index out of range',
                  style: TextStyle(color: Color(0xFF6E6E73)),
                ),
              );
            }

            final currentQuestion =
                state.session.questions[state.currentQuestionIndex];
            final isLastQuestion =
                state.currentQuestionIndex ==
                state.session.questions.length - 1;

            return _buildQuestionContent(
              context,
              currentQuestion,
              state.currentQuestionIndex + 1,
              state.session.questions.length,
              isLastQuestion,
              state.isSubmitting,
            );
          }

          if (state is QnAError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF6E6E73),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: Color(0xFF6E6E73),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QnABloc>().add(
                        StartQnASessionEvent(
                          agentId: widget.agentId,
                          agentName: widget.agentName,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D1F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<QnABloc, QnAState>(
        builder: (context, state) {
          if (state is QnASessionActive) {
            // Safety check to prevent RangeError
            if (state.currentQuestionIndex >= state.session.questions.length) {
              return const SizedBox.shrink();
            }

            final currentQuestion =
                state.session.questions[state.currentQuestionIndex];
            final isLastQuestion =
                state.currentQuestionIndex ==
                state.session.questions.length - 1;
            final canProceed =
                (currentQuestion.type == QuestionType.multipleChoice &&
                    _selectedOption != null) ||
                (currentQuestion.type == QuestionType.textInput &&
                    _textController.text.trim().isNotEmpty);

            if (canProceed) {
              return FloatingActionButton.extended(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (isLastQuestion) {
                          context.read<QnABloc>().add(
                            CompleteQnASessionEvent(),
                          );
                        } else {
                          _submitAnswer(context);
                        }
                      },
                backgroundColor: const Color(0xFF1D1D1F),
                foregroundColor: Colors.white,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                label: Text(
                  state.isSubmitting
                      ? 'Submitting...'
                      : isLastQuestion
                      ? 'Complete'
                      : 'Next',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(Question question, bool isSubmitting) {
    return Column(
      children: question.options!.map((option) {
        final isSelected = _selectedOption == option;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1D1D1F)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForOption(option),
                        color: const Color(0xFF1D1D1F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Option text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option,
                            style: const TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getDescriptionForOption(option),
                            style: const TextStyle(
                              color: Color(0xFF6E6E73),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF1D1D1F),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(Question question, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _textController,
        enabled: !isSubmitting,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: question.placeholder ?? 'Share your thoughts...',
          hintStyle: const TextStyle(color: Color(0xFF6E6E73), fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }

  IconData _getIconForOption(String option) {
    switch (option) {
      case 'Curated Collections':
        return Icons.auto_awesome;
      case 'Latest Trends':
        return Icons.trending_up;
      case 'Timeless Classics':
        return Icons.workspace_premium;
      case 'Unique Finds':
        return Icons.diamond;
      case 'Under ₹50,000':
        return Icons.attach_money;
      case '₹50,000 - ₹2,00,000':
        return Icons.account_balance_wallet;
      case '₹2,00,000 - ₹5,00,000':
        return Icons.savings;
      case 'Above ₹5,00,000':
        return Icons.diamond;
      case 'Monthly':
        return Icons.calendar_month;
      case 'Quarterly':
        return Icons.calendar_view_month;
      case 'Bi-annually':
        return Icons.calendar_today;
      case 'Annually':
        return Icons.event;
      case 'Online only':
        return Icons.shopping_cart;
      case 'In-store only':
        return Icons.store;
      case 'Both equally':
        return Icons.balance;
      case 'Concierge service':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  String _getDescriptionForOption(String option) {
    switch (option) {
      case 'Curated Collections':
        return 'Designer pieces';
      case 'Latest Trends':
        return 'Newest releases';
      case 'Timeless Classics':
        return 'Investment pieces';
      case 'Unique Finds':
        return 'Rare exclusives';
      case 'Under ₹50,000':
        return 'Entry level luxury';
      case '₹50,000 - ₹2,00,000':
        return 'Mid-range luxury';
      case '₹2,00,000 - ₹5,00,000':
        return 'High-end luxury';
      case 'Above ₹5,00,000':
        return 'Ultra luxury';
      case 'Monthly':
        return 'Regular shopper';
      case 'Quarterly':
        return 'Seasonal shopper';
      case 'Bi-annually':
        return 'Occasional shopper';
      case 'Annually':
        return 'Special occasions';
      case 'Online only':
        return 'Digital convenience';
      case 'In-store only':
        return 'Physical experience';
      case 'Both equally':
        return 'Flexible shopping';
      case 'Concierge service':
        return 'Personal assistance';
      default:
        return '';
    }
  }

  void _submitAnswer(BuildContext context) {
    final currentState = context.read<QnABloc>().state;
    if (currentState is QnASessionActive) {
      final currentQuestion =
          currentState.session.questions[currentState.currentQuestionIndex];

      if (currentQuestion.type == QuestionType.multipleChoice) {
        if (_selectedOption == null) return;

        context.read<QnABloc>().add(
          SubmitAnswerEvent(
            questionId: currentQuestion.id,
            selectedOption: _selectedOption,
          ),
        );
      } else {
        if (_textController.text.trim().isEmpty) return;

        context.read<QnABloc>().add(
          SubmitAnswerEvent(
            questionId: currentQuestion.id,
            textAnswer: _textController.text.trim(),
          ),
        );
      }

      // Reset for next question
      _selectedOption = null;
      _textController.clear();
    }
  }
}
