import '../../../domain/entities/google_meet_transcript.dart';

class GoogleMeetTranscriptModel {
  final String id;
  final String userId;
  final String conferenceId;
  final String transcriptName;
  final Map<String, dynamic>? driveDestination;
  final String state;
  final String? startTime;
  final String? endTime;
  final String createdAt;

  const GoogleMeetTranscriptModel({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.transcriptName,
    this.driveDestination,
    required this.state,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory GoogleMeetTranscriptModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetTranscriptModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      conferenceId: json['conference_id'] ?? '',
      transcriptName: json['transcript_name'] ?? '',
      driveDestination: json['drive_destination'],
      state: json['state'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'conference_id': conferenceId,
      'transcript_name': transcriptName,
      'drive_destination': driveDestination,
      'state': state,
      'start_time': startTime,
      'end_time': endTime,
      'created_at': createdAt,
    };
  }

  GoogleMeetTranscript toEntity() {
    return GoogleMeetTranscript(
      id: id,
      userId: userId,
      conferenceId: conferenceId,
      transcriptName: transcriptName,
      driveDestination: driveDestination,
      state: state,
      startTime: startTime != null ? DateTime.parse(startTime!) : null,
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory GoogleMeetTranscriptModel.fromEntity(GoogleMeetTranscript entity) {
    return GoogleMeetTranscriptModel(
      id: entity.id,
      userId: entity.userId,
      conferenceId: entity.conferenceId,
      transcriptName: entity.transcriptName,
      driveDestination: entity.driveDestination,
      state: entity.state,
      startTime: entity.startTime?.toIso8601String(),
      endTime: entity.endTime?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
