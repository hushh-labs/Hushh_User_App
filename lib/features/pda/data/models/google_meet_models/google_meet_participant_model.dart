import '../../../domain/entities/google_meet_participant.dart';

class GoogleMeetParticipantModel {
  final String id;
  final String userId;
  final String conferenceId;
  final String participantName;
  final String? displayName;
  final String? email;
  final String? joinTime;
  final String? leaveTime;
  final int? durationMinutes;
  final String role;
  final String createdAt;

  const GoogleMeetParticipantModel({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.participantName,
    this.displayName,
    this.email,
    this.joinTime,
    this.leaveTime,
    this.durationMinutes,
    required this.role,
    required this.createdAt,
  });

  factory GoogleMeetParticipantModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetParticipantModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      conferenceId: json['conference_id'] ?? '',
      participantName: json['participant_name'] ?? '',
      displayName: json['display_name'],
      email: json['email'],
      joinTime: json['join_time'],
      leaveTime: json['leave_time'],
      durationMinutes: json['duration_minutes'],
      role: json['role'] ?? 'participant',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'conference_id': conferenceId,
      'participant_name': participantName,
      'display_name': displayName,
      'email': email,
      'join_time': joinTime,
      'leave_time': leaveTime,
      'duration_minutes': durationMinutes,
      'role': role,
      'created_at': createdAt,
    };
  }

  GoogleMeetParticipant toEntity() {
    return GoogleMeetParticipant(
      id: id,
      userId: userId,
      conferenceId: conferenceId,
      participantName: participantName,
      displayName: displayName,
      email: email,
      joinTime: joinTime != null ? DateTime.parse(joinTime!) : null,
      leaveTime: leaveTime != null ? DateTime.parse(leaveTime!) : null,
      durationMinutes: durationMinutes,
      role: role,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory GoogleMeetParticipantModel.fromEntity(GoogleMeetParticipant entity) {
    return GoogleMeetParticipantModel(
      id: entity.id,
      userId: entity.userId,
      conferenceId: entity.conferenceId,
      participantName: entity.participantName,
      displayName: entity.displayName,
      email: entity.email,
      joinTime: entity.joinTime?.toIso8601String(),
      leaveTime: entity.leaveTime?.toIso8601String(),
      durationMinutes: entity.durationMinutes,
      role: entity.role,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
