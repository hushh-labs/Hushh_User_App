import 'package:equatable/equatable.dart';

class MultiChoiceQuestions extends Equatable {
  final String question;
  final List<String> options;
  final List<String> selectedOptions;
  final bool isMultiSelect;

  const MultiChoiceQuestions({
    required this.question,
    required this.options,
    this.selectedOptions = const [],
    this.isMultiSelect = false,
  });

  MultiChoiceQuestions copyWith({
    String? question,
    List<String>? options,
    List<String>? selectedOptions,
    bool? isMultiSelect,
  }) {
    return MultiChoiceQuestions(
      question: question ?? this.question,
      options: options ?? this.options,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
    );
  }

  @override
  List<Object?> get props => [
    question,
    options,
    selectedOptions,
    isMultiSelect,
  ];
}
