import '../../../domain/entities/google_meet_recording.dart';

class GoogleMeetRecordingModel {
  final String id;
  final String userId;
  final String conferenceId;
  final String recordingName;
  final Map<String, dynamic>? driveDestination;
  final String state;
  final String? startTime;
  final String? endTime;
  final String createdAt;

  const GoogleMeetRecordingModel({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.recordingName,
    this.driveDestination,
    required this.state,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory GoogleMeetRecordingModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetRecordingModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      conferenceId: json['conference_id'] ?? '',
      recordingName: json['recording_name'] ?? '',
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
      'recording_name': recordingName,
      'drive_destination': driveDestination,
      'state': state,
      'start_time': startTime,
      'end_time': endTime,
      'created_at': createdAt,
    };
  }

  GoogleMeetRecording toEntity() {
    return GoogleMeetRecording(
      id: id,
      userId: userId,
      conferenceId: conferenceId,
      recordingName: recordingName,
      driveDestination: driveDestination,
      state: state,
      startTime: startTime != null ? DateTime.parse(startTime!) : null,
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory GoogleMeetRecordingModel.fromEntity(GoogleMeetRecording entity) {
    return GoogleMeetRecordingModel(
      id: entity.id,
      userId: entity.userId,
      conferenceId: entity.conferenceId,
      recordingName: entity.recordingName,
      driveDestination: entity.driveDestination,
      state: entity.state,
      startTime: entity.startTime?.toIso8601String(),
      endTime: entity.endTime?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
