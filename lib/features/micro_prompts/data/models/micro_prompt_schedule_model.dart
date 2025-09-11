import '../../domain/entities/micro_prompt_schedule.dart';

class MicroPromptScheduleModel extends MicroPromptSchedule {
  const MicroPromptScheduleModel({
    required super.id,
    required super.userId,
    super.lastPromptShownAt,
    super.nextPromptScheduledAt,
    super.quietHoursStart,
    super.quietHoursEnd,
    super.timezone,
    super.isPromptsEnabled,
    super.promptFrequencyMinutes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MicroPromptScheduleModel.fromJson(Map<String, dynamic> json) {
    return MicroPromptScheduleModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lastPromptShownAt: json['last_prompt_shown_at'] != null
          ? DateTime.parse(json['last_prompt_shown_at'] as String)
          : null,
      nextPromptScheduledAt: json['next_prompt_scheduled_at'] != null
          ? DateTime.parse(json['next_prompt_scheduled_at'] as String)
          : null,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '23:00:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00:00',
      timezone: json['timezone'] as String? ?? 'UTC',
      isPromptsEnabled: json['is_prompts_enabled'] as bool? ?? true,
      promptFrequencyMinutes: json['prompt_frequency_minutes'] as int? ?? 30,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'last_prompt_shown_at': lastPromptShownAt?.toIso8601String(),
      'next_prompt_scheduled_at': nextPromptScheduledAt?.toIso8601String(),
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
      'is_prompts_enabled': isPromptsEnabled,
      'prompt_frequency_minutes': promptFrequencyMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MicroPromptScheduleModel.fromEntity(MicroPromptSchedule entity) {
    return MicroPromptScheduleModel(
      id: entity.id,
      userId: entity.userId,
      lastPromptShownAt: entity.lastPromptShownAt,
      nextPromptScheduledAt: entity.nextPromptScheduledAt,
      quietHoursStart: entity.quietHoursStart,
      quietHoursEnd: entity.quietHoursEnd,
      timezone: entity.timezone,
      isPromptsEnabled: entity.isPromptsEnabled,
      promptFrequencyMinutes: entity.promptFrequencyMinutes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MicroPromptSchedule toEntity() {
    return MicroPromptSchedule(
      id: id,
      userId: userId,
      lastPromptShownAt: lastPromptShownAt,
      nextPromptScheduledAt: nextPromptScheduledAt,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      timezone: timezone,
      isPromptsEnabled: isPromptsEnabled,
      promptFrequencyMinutes: promptFrequencyMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
