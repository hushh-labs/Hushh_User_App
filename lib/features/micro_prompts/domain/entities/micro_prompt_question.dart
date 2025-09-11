class MicroPromptQuestion {
  final String id;
  final String questionText;
  final String category;
  final int questionOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MicroPromptQuestion({
    required this.id,
    required this.questionText,
    required this.category,
    required this.questionOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroPromptQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MicroPromptQuestion{id: $id, questionText: $questionText, category: $category, questionOrder: $questionOrder}';
  }
}
