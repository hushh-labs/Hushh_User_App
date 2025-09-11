class MicroPromptSchedule {
  final String id;
  final String userId;
  final DateTime? lastPromptShownAt;
  final DateTime? nextPromptScheduledAt;
  final String quietHoursStart; // Time format: "23:00:00"
  final String quietHoursEnd; // Time format: "07:00:00"
  final String timezone;
  final bool isPromptsEnabled;
  final int promptFrequencyMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MicroPromptSchedule({
    required this.id,
    required this.userId,
    this.lastPromptShownAt,
    this.nextPromptScheduledAt,
    this.quietHoursStart = '23:00:00',
    this.quietHoursEnd = '07:00:00',
    this.timezone = 'UTC',
    this.isPromptsEnabled = true,
    this.promptFrequencyMinutes = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  MicroPromptSchedule copyWith({
    String? id,
    String? userId,
    DateTime? lastPromptShownAt,
    DateTime? nextPromptScheduledAt,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    bool? isPromptsEnabled,
    int? promptFrequencyMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MicroPromptSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastPromptShownAt: lastPromptShownAt ?? this.lastPromptShownAt,
      nextPromptScheduledAt:
          nextPromptScheduledAt ?? this.nextPromptScheduledAt,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
      isPromptsEnabled: isPromptsEnabled ?? this.isPromptsEnabled,
      promptFrequencyMinutes:
          promptFrequencyMinutes ?? this.promptFrequencyMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroPromptSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MicroPromptSchedule{id: $id, userId: $userId, isPromptsEnabled: $isPromptsEnabled, promptFrequencyMinutes: $promptFrequencyMinutes}';
  }
}
