import '../../../domain/entities/google_meet_conference.dart';

class GoogleMeetConferenceModel {
  final String id;
  final String userId;
  final String? spaceId;
  final String conferenceName;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final int participantCount;
  final bool wasRecorded;
  final bool wasTranscribed;
  final String createdAt;
  final String updatedAt;

  const GoogleMeetConferenceModel({
    required this.id,
    required this.userId,
    this.spaceId,
    required this.conferenceName,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.participantCount,
    required this.wasRecorded,
    required this.wasTranscribed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoogleMeetConferenceModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetConferenceModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      spaceId: json['space_id'],
      conferenceName: json['conference_name'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
      participantCount: json['participant_count'] ?? 0,
      wasRecorded: json['was_recorded'] ?? false,
      wasTranscribed: json['was_transcribed'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'space_id': spaceId,
      'conference_name': conferenceName,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'participant_count': participantCount,
      'was_recorded': wasRecorded,
      'was_transcribed': wasTranscribed,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GoogleMeetConference toEntity() {
    return GoogleMeetConference(
      id: id,
      userId: userId,
      spaceId: spaceId,
      conferenceName: conferenceName,
      startTime: startTime != null ? DateTime.parse(startTime!) : null,
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      durationMinutes: durationMinutes,
      participantCount: participantCount,
      wasRecorded: wasRecorded,
      wasTranscribed: wasTranscribed,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  factory GoogleMeetConferenceModel.fromEntity(GoogleMeetConference entity) {
    return GoogleMeetConferenceModel(
      id: entity.id,
      userId: entity.userId,
      spaceId: entity.spaceId,
      conferenceName: entity.conferenceName,
      startTime: entity.startTime?.toIso8601String(),
      endTime: entity.endTime?.toIso8601String(),
      durationMinutes: entity.durationMinutes,
      participantCount: entity.participantCount,
      wasRecorded: entity.wasRecorded,
      wasTranscribed: entity.wasTranscribed,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}
